import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../src/highlight.dart' as hl;
import '../src/icons.dart' as ico;
import '../src/snippets.dart' as snip;
import '../src/ui.dart';

/// One selectable output: the row on the left and the pane it swaps in on the
/// right.
class _Output {
  const _Output({
    required this.id,
    required this.icon,
    required this.name,
    required this.path,
    required this.desc,
    required this.file,
    required this.body,
  });

  final String id;
  final Component icon;
  final String name;

  /// The generated location, shown as the row's monospace suffix.
  final String path;
  final String desc;

  /// The filename on the pane's title bar.
  final String file;
  final Component body;
}

List<_Output> _outputs() => [
  _Output(
    id: 'server',
    icon: ico.server,
    name: 'The server',
    path: 'built in',
    // No backticks: this field renders as plain text, so markdown-style
    // markup would show up literally.
    desc:
        'Routing, binding, validation and the response pipeline — generated, '
        'not written. Run revali routes to see exactly what you got.',
    file: 'dart run revali routes',
    body: codeBlock(hl.shell, snip.routeTable),
  ),
  _Output(
    id: 'client',
    icon: ico.client,
    name: 'A Dart client',
    path: 'revali_client',
    desc:
        'The same method names and the same types, on the other side of the '
        'wire. Drop it into your Flutter app and delete your HTTP layer.',
    file: 'lib/main.dart  (your Flutter app)',
    body: codeBlock(hl.dart, snip.client),
  ),
  _Output(
    id: 'openapi',
    icon: ico.spec,
    name: 'An OpenAPI spec',
    path: 'revali_swagger',
    desc:
        'A valid OpenAPI 3.0.3 document in YAML and JSON, inferred from your '
        'parameters and return types. Zero annotations required.',
    file: '.revali/revali_swagger/swagger.yaml',
    body: codeBlock(hl.yaml, snip.openapi),
  ),
  _Output(
    id: 'docker',
    icon: ico.docker,
    name: 'A Dockerfile',
    path: 'revali_docker',
    desc:
        'A multi-stage build that AOT-compiles your server to a native '
        'executable and ships it on Alpine. Deploy it anywhere.',
    file: '.revali/build/Dockerfile',
    body: codeBlock(hl.dockerfile, snip.dockerfile),
  ),
];

/// "One source of truth" — the annotated controller on the left, and whichever
/// generated artifact you pick on the right.
///
/// Rendered as an ARIA tablist. All four panels are in the HTML; `motion.js`
/// toggles `hidden`. With JS off the first is shown and the rest stay hidden,
/// which is a working, if static, section — and every panel is still in the
/// document for search engines.
class Pipeline extends StatelessComponent {
  const Pipeline();

  @override
  Component build(BuildContext context) {
    final outputs = _outputs();

    return section(
      classes: 'section section--ruled',
      attributes: {'id': 'how'},
      [
        div(classes: 'shell', [
          sectionHead(
            eyebrow: 'One source of truth',
            title: [
              Component.text('Write it once. '),
              span(classes: 'grad-i', [Component.text('Generate the rest.')]),
            ],
            sub:
                'Your controller is the only place an endpoint is described. '
                'Everything downstream is derived from it, so nothing can drift '
                'out of sync — not the client, not the docs, not the deploy.',
          ),
          div(
            classes: 'pipe',
            attributes: {'data-pipeline': ''},
            [
              div(
                classes: 'pipe__tabs',
                attributes: {'role': 'tablist', 'aria-label': 'Generated outputs'},
                [
                  for (final (index, out) in outputs.indexed)
                    button(
                      classes: 'ptab',
                      id: 'ptab-${out.id}',
                      attributes: {
                        'role': 'tab',
                        'aria-selected': '${index == 0}',
                        'aria-controls': 'ppanel-${out.id}',
                        // Roving tabindex: the tablist is one stop in the page's
                        // tab order, and arrow keys move within it.
                        'tabindex': index == 0 ? '0' : '-1',
                        'data-tab': out.id,
                      },
                      [
                        span(classes: 'ptab__ico', [out.icon]),
                        span(classes: 'ptab__txt', [
                          span(classes: 'ptab__name', [
                            Component.text(out.name),
                            code([Component.text(out.path)]),
                          ]),
                          span(classes: 'ptab__desc', [Component.text(out.desc)]),
                        ]),
                      ],
                    ),
                ],
              ),
              div(classes: 'pipe__pane', [
                for (final (index, out) in outputs.indexed)
                  div(
                    classes: 'pipe__panel',
                    id: 'ppanel-${out.id}',
                    attributes: {
                      'role': 'tabpanel',
                      'aria-labelledby': 'ptab-${out.id}',
                      'data-panel': out.id,
                      if (index != 0) 'hidden': '',
                    },
                    [
                      window(
                        title: out.file,
                        badge: 'generated',
                        badgeKind: 'gen',
                        live: true,
                        child: out.body,
                      ),
                    ],
                  ),
              ]),
            ],
          ),
        ]),
      ],
    );
  }
}
