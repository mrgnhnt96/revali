/// Small building blocks shared by more than one section.
library;

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'highlight.dart';
import 'icons.dart' as ico;

/// A syntax-highlighted `<pre>`.
Component codeBlock(Grammar grammar, String source) {
  return pre(classes: 'code', [Component.element(tag: 'code', children: grammar(source.trim()))]);
}

/// A titled pane with traffic lights — the page's one container for code.
///
/// [live] lights the traffic lights, marking a pane as the foreground window.
/// [badge] is the small right-hand tag; pass [badgeKind] `'yours'` (amber) or
/// `'gen'` (indigo) to state whether the contents were hand-written or
/// generated, which is the distinction the whole page turns on.
Component window({
  required String title,
  required Component child,
  Component? icon,
  String? badge,
  String badgeKind = '',
  bool live = false,
  String classes = '',
  Map<String, String>? attributes,
}) {
  return div(
    classes: 'win${live ? ' win--live' : ''}${classes.isEmpty ? '' : ' $classes'}',
    attributes: attributes,
    [
      div(classes: 'win__bar', [
        div(classes: 'win__dots', [i([]), i([]), i([])]),
        div(classes: 'win__title', [
          ?icon,
          span([Component.text(title)]),
        ]),
        if (badge != null)
          span(classes: 'win__badge${badgeKind.isEmpty ? '' : ' win__badge--$badgeKind'}', [
            Component.text(badge),
          ]),
      ]),
      div(classes: 'win__body', [child]),
    ],
  );
}

/// A button that copies [text] to the clipboard.
///
/// The value travels in a `data-copy` attribute rather than being read out of
/// the DOM, so the copied string is exactly what was intended — no leading
/// prompt, no soft-wrapped whitespace picked up from the rendered text.
Component copyButton(String text, {String label = 'copy'}) {
  return button(
    classes: 'copy',
    attributes: {'data-copy': text, 'aria-label': 'Copy to clipboard'},
    [
      ico.copy,
      span([Component.text(label)]),
    ],
  );
}

/// Wraps [children] in a marker that `motion.js` reveals on scroll.
///
/// [delay] staggers siblings. Keep it small — past about 300ms a reveal stops
/// reading as choreography and starts reading as lag.
Component reveal(List<Component> children, {int delay = 0, String classes = ''}) {
  return div(
    classes: classes,
    attributes: {'data-reveal': '', if (delay > 0) 'style': '--d:${delay}ms'},
    children,
  );
}

/// The eyebrow / title / subtitle block above each section.
Component sectionHead({
  required String eyebrow,
  required List<Component> title,
  String? sub,
  bool center = false,
}) {
  return div(
    classes: 'section-head${center ? ' section-head--center' : ''}',
    attributes: {'data-reveal': ''},
    [
      div(classes: 'eyebrow${center ? ' eyebrow--center' : ''}', [Component.text(eyebrow)]),
      h2(classes: 'section-title', title),
      if (sub != null) p(classes: 'section-sub', [Component.text(sub)]),
    ],
  );
}
