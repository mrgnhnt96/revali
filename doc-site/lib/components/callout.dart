/// Admonition boxes: `<Callout type="tip">`, `<Callout type="danger">`, …
///
/// Replaces `jaspr_content`'s own [Callout], which offers four kinds
/// (Info/Warning/Error/Success). The Docusaurus site used seven, and 145 of the
/// 196 callouts on this site are `tip` or `important` — collapsing those onto
/// "Info" would have flattened the one distinction the docs lean on hardest.
///
/// Written in markdown as:
///
/// ```md
/// <Callout type="tip" title="Optional heading">
///
/// Body text. **Markdown works here** because of the blank lines.
///
/// </Callout>
/// ```
///
/// **The blank lines are mandatory.** `package:markdown` treats an HTML block
/// as literal text until a blank line, so text on the line after the opening
/// tag renders with its asterisks and link syntax visible. The failure is
/// silent and reads like a content mistake.
library;

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';

/// The seven admonition kinds, each with a default heading and an accent hue.
///
/// Hues are given as raw CSS `oklch` lightness/chroma/hue triples rather than
/// named colors so that one `color-mix` formula below can derive the border,
/// background and text tints for both themes from a single number.
enum CalloutKind {
  note('Note', _pencilIcon, '250'),
  tip('Tip', _lightbulbIcon, '160'),
  info('Info', _infoIcon, '250'),
  important('Important', _starIcon, '295'),
  warning('Warning', _alertIcon, '85'),
  caution('Caution', _alertIcon, '55'),
  danger('Danger', _flameIcon, '25');

  const CalloutKind(this.label, this.icon, this.hue);

  /// Heading shown when the markdown gives no `title`.
  final String label;

  /// Inline SVG, sized 18x18 to sit on the cap height of the heading.
  final String icon;

  /// OKLCH hue angle, in degrees.
  final String hue;

  static CalloutKind parse(String? value) => switch (value?.toLowerCase()) {
    'tip' => tip,
    'info' => info,
    'important' => important,
    'warning' => warning,
    'caution' => caution,
    'danger' || 'error' => danger,
    _ => note,
  };
}

/// The `<Callout>` markdown component.
final class Callout extends CustomComponentBase {
  const Callout();

  @override
  Pattern get pattern => RegExp(r'^Callout$');

  @override
  Component apply(String name, Map<String, String> attributes, Component? child) {
    return CalloutBox(
      kind: CalloutKind.parse(attributes['type']),
      title: attributes['title'],
      child: child ?? const Component.empty(),
    );
  }
}

/// A rendered admonition. Also usable directly from Dart.
final class CalloutBox extends StatelessComponent {
  const CalloutBox({required this.kind, this.title, required this.child, super.key});

  final CalloutKind kind;
  final String? title;
  final Component child;

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      Document.head(children: [Style(styles: _styles)]),
      aside(
        classes: 'admonition admonition-${kind.name}',
        // The hue drives every tint on the box; see `_styles`.
        styles: Styles(raw: {'--admonition-hue': kind.hue}),
        [
          div(classes: 'admonition-heading', [
            span(classes: 'admonition-icon', [RawText(kind.icon)]),
            span([Component.text(title ?? kind.label)]),
          ]),
          div(classes: 'admonition-body', [child]),
        ],
      ),
    ]);
  }
}

// Lucide-style strokes at 18x18. `currentColor` so each box's own accent
// applies without a per-kind icon color.
const _iconOpen =
    '<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" '
    'stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">';

const _pencilIcon =
    '$_iconOpen<path d="M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 '
    '.623.622l4.353-1.32a2 2 0 0 0 .83-.497z"/><path d="m15 5 4 4"/></svg>';

const _lightbulbIcon =
    '$_iconOpen<path d="M15 14c.2-1 .7-1.7 1.5-2.5 1-.9 1.5-2.2 1.5-3.5A6 6 0 0 0 6 8c0 1 .2 2.2 1.5 3.5.7.7 1.3 '
    '1.5 1.5 2.5"/><path d="M9 18h6"/><path d="M10 22h4"/></svg>';

const _infoIcon =
    '$_iconOpen<circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/></svg>';

const _starIcon =
    '$_iconOpen<path d="M11.525 2.295a.53.53 0 0 1 .95 0l2.31 4.679a2.12 2.12 0 0 0 1.595 1.16l5.166.756a.53.53 0 '
    '0 1 .294.904l-3.736 3.638a2.12 2.12 0 0 0-.611 1.878l.882 5.14a.53.53 0 0 1-.771.56l-4.618-2.428a2.12 2.12 0 '
    '0 0-1.973 0L6.396 21.01a.53.53 0 0 1-.77-.56l.881-5.139a2.12 2.12 0 0 0-.611-1.879L2.16 9.795a.53.53 0 0 1 '
    '.294-.906l5.165-.755a2.12 2.12 0 0 0 1.597-1.16z"/></svg>';

const _alertIcon =
    '$_iconOpen<path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3"/>'
    '<path d="M12 9v4"/><path d="M12 17h.01"/></svg>';

const _flameIcon =
    '$_iconOpen<path d="M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.072-2.143-.224-4.054 2-6 .5 2.5 2 4.9 4 '
    '6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.153.433-2.294 1-3a2.5 2.5 0 0 0 2.5 2.5z"/></svg>';

/// The accent color for the current box, at [alpha] opacity.
///
/// One formula, seven boxes: `--admonition-hue` is the only thing that differs
/// between kinds, and the lightness is swapped wholesale under `[data-theme]`
/// so a mid-tone accent that reads on white becomes a light one that reads on
/// near-black.
String _accent(String alpha) =>
    'oklch(var(--admonition-lightness) var(--admonition-chroma) var(--admonition-hue) / $alpha)';

List<StyleRule> get _styles => [
  css('.admonition', [
    css('&').styles(
      raw: {
        '--admonition-lightness': '0.52',
        '--admonition-chroma': '0.16',
        'border-left': '3px solid ${_accent("1")}',
      },
      padding: Padding.symmetric(horizontal: 1.rem, vertical: .875.rem),
      margin: Margin.symmetric(vertical: 1.25.rem),
      radius: BorderRadius.only(
        topRight: Radius.circular(.5.rem),
        bottomRight: Radius.circular(.5.rem),
      ),
      backgroundColor: Color(_accent('0.07')),
    ),
    css('.admonition-heading', [
      css('&').styles(
        display: Display.flex,
        margin: Margin.only(bottom: .375.rem),
        alignItems: AlignItems.center,
        gap: Gap.column(.5.rem),
        color: Color(_accent('1')),
        fontSize: .8125.rem,
        fontWeight: FontWeight.w700,
        textTransform: TextTransform.upperCase,
        letterSpacing: .04.em,
      ),
      css('.admonition-icon').styles(display: Display.flex, flex: Flex(shrink: 0)),
    ]),
    css('.admonition-body', [
      // Markdown inside a callout still emits paragraphs; without this the box
      // grows a blank line at each end.
      css('> :first-child').styles(margin: Margin.only(top: Unit.zero)),
      css('> :last-child').styles(margin: Margin.only(bottom: Unit.zero)),
    ]),
  ]),

  // Mid-tone accents disappear against a dark background; lift the lightness
  // and drop the chroma rather than restating seven colors.
  css(
    '[data-theme="dark"] .admonition',
  ).styles(raw: {'--admonition-lightness': '0.78', '--admonition-chroma': '0.13'}),

  // `note` is the one kind that should recede: it is the default, and a blue
  // box around every aside turns the page into a stack of boxes.
  css('.admonition-note').styles(raw: {'--admonition-chroma': '0.03'}),
  css('[data-theme="dark"] .admonition-note').styles(raw: {'--admonition-chroma': '0.02'}),
];
