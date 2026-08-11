/// Client-side full-text search for the docs.
///
/// The site is static (GitHub Pages), so there is nothing to query server-side,
/// and this replaced an Algolia DocSearch integration — which meant a crawler,
/// an API key in the config, and results that lagged a deploy. Instead
/// `tool/build_search_index.dart` emits `web/search-index.json` — one record per
/// heading-delimited section — and this component fetches it the first time the
/// dialog is opened, then scores it in the browser.
///
/// The index is ~470 KB uncompressed (~110 KB over the wire) and is only
/// fetched on first use, so it costs nothing for readers who never search.
library;

import 'dart:async';
import 'dart:convert';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/theme.dart';
// `universal_web`'s shim, not `dart:js_interop` — this file is compiled for
// the server too (the header renders it during pre-rendering), where
// `dart:js_interop` is unavailable.
import 'package:universal_web/js_interop.dart';
import 'package:universal_web/web.dart' as web;

import '../src/search_index.dart';

/// The search trigger in the header, plus the dialog it opens.
///
/// Opens on click, `⌘K` / `Ctrl+K`, or `/`. Closes on `Esc` or a click on the
/// backdrop. Arrow keys move the selection; `Enter` navigates.
@client
final class DocsSearch extends StatefulComponent {
  const DocsSearch({super.key});

  @override
  State<DocsSearch> createState() => _DocsSearchState();
}

/// There is exactly one search dialog per page, so the elements are looked up
/// by id rather than by `GlobalNodeKey` — `currentNode`'s type test does not
/// survive `universal_web`'s extension types under dart2js, and silently
/// returns null.
const _dialogId = 'docs-search-dialog';
const _inputId = 'docs-search-input';

class _DocsSearchState extends State<DocsSearch> {
  StreamSubscription<web.KeyboardEvent>? _shortcuts;

  bool _open = false;

  /// Whether the dialog node has been promoted into the top layer.
  ///
  /// Tracked separately from [_open] because the `open` attribute has to be
  /// absent for the `showModal()` call and present for every render after it —
  /// see [_openDialog].
  bool _shown = false;
  bool _loading = false;
  String? _error;
  String _query = '';
  int _selected = 0;
  bool _isApple = true;

  List<SearchDoc>? _index;
  List<SearchHit> _hits = const [];

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;

    _isApple = RegExp('Mac|iPhone|iPad|iPod').hasMatch(web.window.navigator.platform);
    _shortcuts = web.window.onKeyDown.listen(_onGlobalKey);
  }

  @override
  void dispose() {
    _shortcuts?.cancel();
    _setScrollLock(false);
    super.dispose();
  }

  void _onGlobalKey(web.KeyboardEvent event) {
    final key = event.key.toLowerCase();

    if (_open) {
      if (key == 'escape') {
        event.preventDefault();
        _close();
      }
      return;
    }

    final shortcut = key == 'k' && (event.metaKey || event.ctrlKey);
    // Bare `/` is a common docs shortcut, but must not steal real typing.
    final slash = event.key == '/' && !_isTypingTarget(event.target);
    if (!shortcut && !slash) return;

    event.preventDefault();
    _openDialog();
  }

  static bool _isTypingTarget(web.EventTarget? target) {
    // `is!` cannot narrow a JS interop extension type: it compiles to "is this
    // a JSObject", which is always true, so the guard would never fire and the
    // properties below would be read off whatever the event target happened to
    // be. `isA` does the real underlying-type check. The symptom it prevents is
    // ⌘K/`/` hijacking a keystroke while the reader is typing in a form field.
    if (target == null || !target.isA<web.HTMLElement>()) return false;
    final element = target as web.HTMLElement;
    return element.isContentEditable ||
        element.tagName == 'INPUT' ||
        element.tagName == 'TEXTAREA' ||
        element.tagName == 'SELECT';
  }

  void _openDialog() {
    if (_open) return;
    setState(() {
      _open = true;
      _shown = false;
      _selected = 0;
      _query = '';
      _hits = const [];
    });
    _setScrollLock(true);
    unawaited(_loadIndex());
    // The dialog element does not exist until this frame has been flushed to
    // the DOM, so this cannot be a microtask.
    context.binding.addPostFrameCallback(() {
      // `showModal` promotes the dialog into the browser's top layer. That is
      // the point: the header sets `backdrop-filter`, which makes it the
      // containing block for `position: fixed` descendants, so a plain fixed
      // overlay rendered here would be sized to the header rather than the
      // viewport. Top-layer elements are always viewport-relative.
      //
      // It throws if the `open` attribute is already present, so the first
      // render omits it; `_shown` then keeps it on for every render after,
      // because Jaspr reconciles the attribute away otherwise and that
      // silently closes the dialog on the next `setState`.
      final node = _dialogNode;
      if (node != null && !node.open) {
        node.showModal();
        setState(() => _shown = true);
      }
      _inputNode?.focus();
    });
  }

  web.HTMLDialogElement? get _dialogNode =>
      web.document.getElementById(_dialogId) as web.HTMLDialogElement?;

  web.HTMLInputElement? get _inputNode =>
      web.document.getElementById(_inputId) as web.HTMLInputElement?;

  void _close() {
    if (!_open) return;
    _dialogNode?.close();
    setState(() {
      _open = false;
      _shown = false;
    });
    _setScrollLock(false);
  }

  void _setScrollLock(bool locked) {
    if (!kIsWeb) return;
    (web.document.documentElement as web.HTMLElement?)?.style.overflow = locked ? 'hidden' : '';
  }

  Future<void> _loadIndex() async {
    if (_index != null || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await web.window.fetch(_resolve('search-index.json').toJS).toDart;
      if (!response.ok) {
        throw StateError('HTTP ${response.status}');
      }
      final payload = jsonDecode((await response.text().toDart).toDart) as Map<String, Object?>;
      final docs = [
        for (final doc in payload['docs']! as List) SearchDoc.fromJson(doc as Map<String, Object?>),
      ];

      if (!mounted) return;
      setState(() {
        _index = docs;
        _loading = false;
      });
      _runQuery(_query);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load the search index ($error).';
      });
    }
  }

  /// Resolves [path] against `<base href>`.
  ///
  /// Result links are built in the browser, so they miss the deploy's
  /// absolute-URL rewrite. Resolving against the base keeps them correct
  /// whether the site is served from a domain root or a `/repo/` subpath.
  String _resolve(String path) {
    final base = Uri.parse(web.document.baseURI);
    return base.resolve(path.startsWith('/') ? path.substring(1) : path).toString();
  }

  void _runQuery(String query) {
    _query = query;
    final index = _index;
    setState(() {
      _selected = 0;
      _hits = index == null ? const [] : searchIndex(index, query);
    });
  }

  void _move(int delta) {
    if (_hits.isEmpty) return;
    setState(() {
      _selected = (_selected + delta) % _hits.length;
      if (_selected < 0) _selected += _hits.length;
    });
    _scrollSelectedIntoView();
  }

  void _scrollSelectedIntoView() {
    if (!kIsWeb) return;
    context.binding.addPostFrameCallback(() {
      web.document
          .querySelector('.search-hit[data-selected]')
          ?.scrollIntoView({'block': 'nearest'}.jsify()!);
    });
  }

  void _openSelected() {
    if (_selected >= _hits.length) return;
    web.window.location.href = _resolve(_hits[_selected].href);
  }

  void _onInputKey(web.Event event) {
    // `isA`, not `is`, for the same reason as [_isTypingTarget].
    if (!event.isA<web.KeyboardEvent>()) return;
    switch ((event as web.KeyboardEvent).key) {
      case 'ArrowDown':
        event.preventDefault();
        _move(1);
      case 'ArrowUp':
        event.preventDefault();
        _move(-1);
      case 'Enter':
        event.preventDefault();
        _openSelected();
    }
  }

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      if (!kIsWeb) Document.head(children: [Style(styles: _styles)]),
      button(
        classes: 'search-trigger',
        attributes: {'aria-label': 'Search the documentation', 'type': 'button'},
        onClick: _openDialog,
        [
          RawText(_searchIcon),
          span(classes: 'search-trigger-label', [Component.text('Search')]),
          span(classes: 'search-trigger-keys', [Component.text(_isApple ? '⌘K' : 'Ctrl K')]),
        ],
      ),
      if (_open) _dialog(),
    ]);
  }

  Component _dialog() {
    return dialog(
      id: _dialogId,
      open: _shown,
      classes: 'search-dialog',
      attributes: {'aria-label': 'Search'},
      events: {
        // A modal dialog's backdrop is painted by the dialog itself, so a click
        // that lands on the backdrop targets the dialog element.
        'click': (event) {
          if ((event.target as web.Element?)?.id == _dialogId) _close();
        },
        // Esc: cancel the native close so teardown goes through one path.
        'cancel': (event) {
          event.preventDefault();
          _close();
        },
      },
      [
        div(classes: 'search-panel', [
          div(classes: 'search-field', [
            RawText(_searchIcon),
            input(
              id: _inputId,
              type: InputType.text,
              attributes: {
                'placeholder': 'Search the docs…',
                'autocomplete': 'off',
                'spellcheck': 'false',
                'aria-label': 'Search query',
              },
              onInput: (String value) => _runQuery(value),
              events: {'keydown': _onInputKey},
            ),
            button(
              classes: 'search-dismiss',
              attributes: {'type': 'button', 'aria-label': 'Close search'},
              onClick: _close,
              [Component.text('Esc')],
            ),
          ]),
          div(classes: 'search-results', [_results()]),
          div(classes: 'search-footer', [
            span([RawText('<kbd>↑</kbd><kbd>↓</kbd> to navigate')]),
            span([RawText('<kbd>↵</kbd> to open')]),
            span([RawText('<kbd>esc</kbd> to close')]),
          ]),
        ]),
      ],
    );
  }

  Component _results() {
    if (_error case final error?) {
      return div(classes: 'search-empty', [Component.text(error)]);
    }
    if (_loading && _index == null) {
      return div(classes: 'search-empty', [Component.text('Loading search index…')]);
    }
    if (_query.trim().isEmpty) {
      return div(classes: 'search-empty', [
        Component.text('Search titles, headings and body text across all '),
        strong([Component.text('${_index?.length ?? 0}')]),
        Component.text(' pages.'),
      ]);
    }
    if (_hits.isEmpty) {
      return div(classes: 'search-empty', [
        Component.text('No matches for “$_query”. '),
        // Every token has to match, so a two-word query with one unknown word
        // returns nothing — worth saying, since the alternative reading is
        // "search is broken".
        span(classes: 'search-hint', [
          Component.text('Every word has to match. Try fewer, or more common, words.'),
        ]),
      ]);
    }

    final tokens = tokenize(_query);
    return ul(classes: 'search-hit-list', [
      for (final (index, hit) in _hits.indexed)
        li([
          a(
            href: _resolveOrRaw(hit.href),
            classes: 'search-hit',
            attributes: {if (index == _selected) 'data-selected': 'true'},
            events: {'mouseenter': (_) => setState(() => _selected = index)},
            [
              div(classes: 'search-hit-crumb', [
                if (hit.group.isNotEmpty) ...[
                  span([Component.text(hit.group)]),
                  span(classes: 'search-hit-sep', [Component.text('/')]),
                ],
                span([Component.text(hit.title)]),
              ]),
              div(classes: 'search-hit-heading', [..._highlight(hit.heading ?? hit.title, tokens)]),
              if (hit.snippet.isNotEmpty)
                div(classes: 'search-hit-snippet', [..._highlight(hit.snippet, tokens)]),
            ],
          ),
        ]),
    ]);
  }

  /// Anchor hrefs are resolved eagerly so middle-click and "copy link" work.
  String _resolveOrRaw(String href) => kIsWeb ? _resolve(href) : href;
}

/// Wraps every occurrence of [tokens] in [source] with a `<mark>`.
///
/// Built as components rather than raw HTML so nothing in the index can inject
/// markup into the page.
List<Component> _highlight(String source, List<String> tokens) {
  if (tokens.isEmpty) return [Component.text(source)];

  final lower = source.toLowerCase();
  final marked = List<bool>.filled(source.length, false);

  for (final token in tokens) {
    var from = 0;
    while (true) {
      final at = lower.indexOf(token, from);
      if (at < 0) break;
      marked.fillRange(at, at + token.length, true);
      from = at + token.length;
    }
  }

  final parts = <Component>[];
  var start = 0;
  while (start < source.length) {
    final isMark = marked[start];
    var end = start;
    while (end < source.length && marked[end] == isMark) {
      end++;
    }
    final chunk = source.substring(start, end);
    parts.add(
      isMark
          ? Component.element(tag: 'mark', children: [Component.text(chunk)])
          : Component.text(chunk),
    );
    start = end;
  }
  return parts;
}

const _searchIcon =
    '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" '
    'stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">'
    '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>';

const _hairline = 'color-mix(in srgb, currentColor 12%, transparent)';

List<StyleRule> get _styles => [
  css('.search-trigger', [
    css('&').styles(
      display: Display.flex,
      height: 2.rem,
      padding: Padding.symmetric(horizontal: .7.rem),
      border: Border.all(
        width: 1.px,
        color: Color('color-mix(in srgb, currentColor 15%, transparent)'),
      ),
      radius: BorderRadius.circular(8.px),
      opacity: .8,
      cursor: Cursor.pointer,
      transition: Transition('all', duration: 150.ms, curve: Curve.easeInOut),
      alignItems: AlignItems.center,
      gap: Gap.column(.5.rem),
      color: Color('inherit'),
      fontSize: .8125.rem,
      backgroundColor: Colors.transparent,
    ),
    css('&:hover').styles(
      opacity: 1,
      backgroundColor: Color('color-mix(in srgb, currentColor 6%, transparent)'),
    ),
    css('.search-trigger-label').styles(display: Display.none),
    css('.search-trigger-keys').styles(
      display: Display.none,
      opacity: .7,
      fontFamily: FontFamily.list([FontFamilies.monospace]),
      fontSize: .6875.rem,
    ),
    css.media(MediaQuery.all(minWidth: 640.px), [
      css('&').styles(width: 12.rem, justifyContent: JustifyContent.start),
      css('.search-trigger-label').styles(display: Display.block),
      css('.search-trigger-keys').styles(
        display: Display.block,
        margin: Margin.only(left: Unit.auto),
      ),
    ]),
  ]),

  // A modal `<dialog>` lives in the top layer, so these sizes resolve against
  // the viewport even though the header (an ancestor) sets `backdrop-filter`.
  // The browser's own UA styles for `dialog` have to be undone explicitly.
  css('.search-dialog', [
    css('&').styles(
      display: Display.none,
      width: 100.percent,
      height: 100.percent,
      maxWidth: Unit.initial,
      maxHeight: Unit.initial,
      padding: Padding.symmetric(horizontal: 1.rem, vertical: 3.rem),
      margin: Margin.zero,
      border: Border.none,
      overflow: Overflow.hidden,
      color: Color('inherit'),
      backgroundColor: Colors.transparent,
    ),
    css('&[open]').styles(
      display: Display.flex,
      justifyContent: JustifyContent.center,
      alignItems: AlignItems.start,
    ),
    css('&::backdrop').styles(
      backgroundColor: Color('rgba(15, 23, 42, .45)'),
      raw: {'backdrop-filter': 'blur(4px)'},
    ),
    css.media(MediaQuery.all(minWidth: 768.px), [
      css('&').styles(
        padding: Padding.only(top: 6.rem, left: 1.rem, right: 1.rem, bottom: 3.rem),
      ),
    ]),
  ]),

  css('.search-panel').styles(
    display: Display.flex,
    width: 100.percent,
    maxWidth: 40.rem,
    maxHeight: 100.percent,
    border: Border.all(width: 1.px, color: Color(_hairline)),
    radius: BorderRadius.circular(14.px),
    overflow: Overflow.hidden,
    flexDirection: FlexDirection.column,
    backgroundColor: ContentColors.background,
    raw: {'box-shadow': '0 24px 60px rgba(0,0,0,.28)'},
  ),

  css('.search-field', [
    css('&').styles(
      display: Display.flex,
      height: 3.5.rem,
      padding: Padding.symmetric(horizontal: 1.rem),
      border: Border.only(
        bottom: BorderSide(width: 1.px, color: Color(_hairline)),
      ),
      alignItems: AlignItems.center,
      gap: Gap.column(.75.rem),
    ),
    css('svg').styles(opacity: .5, flex: Flex(shrink: 0)),
    css('input').styles(
      minWidth: Unit.zero,
      border: Border.none,
      outline: Outline(style: OutlineStyle.none),
      flex: Flex(grow: 1),
      color: Color('inherit'),
      fontFamily: FontFamily.inherit,
      fontSize: 1.rem,
      backgroundColor: Colors.transparent,
    ),
  ]),

  css('.search-dismiss', [
    css('&').styles(
      padding: Padding.symmetric(horizontal: .5.rem, vertical: .25.rem),
      border: Border.all(
        width: 1.px,
        color: Color('color-mix(in srgb, currentColor 18%, transparent)'),
      ),
      radius: BorderRadius.circular(6.px),
      opacity: .6,
      cursor: Cursor.pointer,
      flex: Flex(shrink: 0),
      color: Color('inherit'),
      fontSize: .6875.rem,
      backgroundColor: Colors.transparent,
    ),
    css('&:hover').styles(opacity: 1),
  ]),

  css('.search-results').styles(
    padding: Padding.all(.5.rem),
    overflow: Overflow.only(y: Overflow.auto),
  ),

  css('.search-empty', [
    css('&').styles(
      padding: Padding.all(1.5.rem),
      opacity: .7,
      textAlign: TextAlign.center,
      fontSize: .875.rem,
    ),
    css('.search-hint').styles(
      display: Display.block,
      margin: Margin.only(top: .5.rem),
      opacity: .8,
      fontSize: .8125.rem,
    ),
  ]),

  css(
    '.search-hit-list',
  ).styles(padding: Padding.zero, margin: Margin.zero, listStyle: ListStyle.none),

  css('.search-hit', [
    css('&').styles(
      display: Display.block,
      padding: Padding.symmetric(horizontal: .875.rem, vertical: .625.rem),
      radius: BorderRadius.circular(10.px),
      color: Color('inherit'),
      textDecoration: TextDecoration.none,
    ),
    css(
      '&[data-selected]',
    ).styles(backgroundColor: Color('color-mix(in srgb, currentColor 8%, transparent)')),
    css('.search-hit-crumb', [
      css('&').styles(
        display: Display.flex,
        opacity: .6,
        gap: Gap.column(.375.rem),
        fontSize: .6875.rem,
        textTransform: TextTransform.upperCase,
        letterSpacing: .04.em,
      ),
      css('.search-hit-sep').styles(opacity: .5),
    ]),
    css('.search-hit-heading').styles(
      margin: Margin.only(top: .125.rem),
      fontSize: .9375.rem,
      fontWeight: FontWeight.w600,
    ),
    css('.search-hit-snippet').styles(
      margin: Margin.only(top: .1875.rem),
      opacity: .72,
      fontSize: .8125.rem,
      lineHeight: 1.4.em,
    ),
    css('mark').styles(
      padding: Padding.symmetric(horizontal: 1.px),
      radius: BorderRadius.circular(3.px),
      color: ContentColors.primary,
      fontWeight: FontWeight.w600,
      backgroundColor: Color('color-mix(in srgb, currentColor 18%, transparent)'),
    ),
  ]),

  css('.search-footer', [
    css('&').styles(
      display: Display.flex,
      padding: Padding.symmetric(horizontal: 1.rem, vertical: .625.rem),
      border: Border.only(
        top: BorderSide(width: 1.px, color: Color(_hairline)),
      ),
      opacity: .55,
      gap: Gap.column(1.rem),
      fontSize: .6875.rem,
    ),
    css('kbd').styles(
      padding: Padding.symmetric(horizontal: .25.rem),
      margin: Margin.only(right: .25.rem),
      border: Border.all(
        width: 1.px,
        color: Color('color-mix(in srgb, currentColor 20%, transparent)'),
      ),
      radius: BorderRadius.circular(4.px),
      fontFamily: FontFamily.list([FontFamilies.monospace]),
    ),
  ]),
];
