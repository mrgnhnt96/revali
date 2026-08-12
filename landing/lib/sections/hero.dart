import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../src/highlight.dart' as hl;
import '../src/icons.dart' as ico;
import '../src/snippets.dart' as snip;
import '../src/ui.dart';

/// The four things Revali generates, as the labelled outputs under the hero's
/// source pane. Kept in this order everywhere on the page: server first
/// because it is built in, then the three optional constructs.
final _outputs = [
  (ico.server, 'Server', '.revali/server'),
  (ico.client, 'Dart client', '.revali/revali_client'),
  (ico.spec, 'OpenAPI 3.0.3', 'swagger.yaml'),
  (ico.docker, 'Dockerfile', '.revali/build'),
];

class Hero extends StatelessComponent {
  const Hero();

  @override
  Component build(BuildContext context) {
    return section(classes: 'hero', [
      div(classes: 'shell', [
        div(classes: 'hero__grid', [_copy(), const _Visual()]),
      ]),
    ]);
  }

  Component _copy() {
    return div(
      attributes: {'data-reveal': ''},
      [
        a(
          classes: 'hero__pill',
          href: 'https://pub.dev/packages/revali',
          attributes: {'target': '_blank', 'rel': 'noopener'},
          [
            b([Component.text('pub.dev')]),
            span([Component.text('revali is live on pub')]),
            ico.arrow,
          ],
        ),
        h1([
          Component.text('Annotate your Dart.'),
          br(),
          span(classes: 'grad', [Component.text('Ship the whole API.')]),
        ]),
        p(classes: 'hero__lede', [
          Component.text(
            'Revali reads the annotations on your classes and generates '
            'the server, a type-safe Dart client, an OpenAPI document and a '
            'production Dockerfile. You write business logic — ',
          ),
          code([Component.text('revali dev')]),
          Component.text(' writes the rest, and hot reloads it.'),
        ]),
        div(classes: 'hero__cta', [
          a(
            classes: 'btn btn--primary btn--lg',
            href: 'https://docs.revali.dev/revali/getting-started/installation',
            [Component.text('Get started'), ico.arrow],
          ),
          a(
            classes: 'btn btn--ghost btn--lg',
            href: 'https://github.com/mrgnhnt96/revali',
            attributes: {'target': '_blank', 'rel': 'noopener'},
            [ico.github, Component.text('Star on GitHub')],
          ),
        ]),
        div(classes: 'hero__note', [
          i([ico.check, Component.text('Pure Dart, no build_runner')]),
          i([ico.check, Component.text('Hot reload')]),
          i([ico.check, Component.text('MIT licensed')]),
        ]),
      ],
    );
  }
}

/// The hero's right-hand column: one source pane, a wire, four outputs.
///
/// This is the page's thesis rendered as a picture — everything below it is
/// elaboration, so it has to be readable before a single word is.
class _Visual extends StatelessComponent {
  const _Visual();

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'heroviz',
      attributes: {'data-reveal': '', 'style': '--d:120ms'},
      [
        div(classes: 'heroviz__source', [
          window(
            title: 'routes/users_controller.dart',
            badge: 'yours',
            badgeKind: 'yours',
            live: true,
            child: codeBlock(hl.dart, snip.source),
          ),
        ]),
        div(classes: 'heroviz__wire', []),
        div(classes: 'heroviz__outs', [
          for (final (icon, name, path) in _outputs)
            div(classes: 'heroviz__out', [
              icon,
              div([
                b([Component.text(name)]),
                br(),
                Component.text(path),
              ]),
            ]),
        ]),
      ],
    );
  }
}
