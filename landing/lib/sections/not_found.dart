import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../src/icons.dart' as ico;

/// The page GitHub Pages serves for any path that does not exist.
class NotFound extends StatelessComponent {
  const NotFound();

  @override
  Component build(BuildContext context) {
    return section(classes: 'section notfound', [
      div(classes: 'shell', [
        div(classes: 'eyebrow eyebrow--center', [Component.text('404')]),
        h1(classes: 'section-title', [Component.text('This page is not here.')]),
        p(classes: 'section-sub', [
          Component.text('The link may be old, or the page may have moved to the docs.'),
        ]),
        div(classes: 'notfound__links', [
          a(classes: 'btn btn--primary btn--lg', href: '/', [
            Component.text('Go to the home page'),
            ico.arrow,
          ]),
          a(classes: 'btn btn--ghost btn--lg', href: 'https://docs.revali.dev', [
            Component.text('Read the docs'),
          ]),
        ]),
      ]),
    ]);
  }
}
