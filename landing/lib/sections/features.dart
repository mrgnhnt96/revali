import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../src/highlight.dart' as hl;
import '../src/icons.dart' as ico;
import '../src/snippets.dart' as snip;
import '../src/ui.dart';

/// The "yes, it does the real things" section.
///
/// A developer evaluating a framework is running a checklist — auth, DI,
/// websockets, validation, deployment — and the fastest way to pass it is to
/// show the code for each rather than claim it. So the larger cards here carry
/// snippets, not adjectives.
class Features extends StatelessComponent {
  const Features();

  @override
  Component build(BuildContext context) {
    return section(
      classes: 'section section--ruled',
      attributes: {'id': 'features'},
      [
        div(classes: 'shell', [
          sectionHead(
            eyebrow: 'Batteries included',
            title: [
              Component.text('Everything a real API needs, '),
              span(classes: 'grad', [Component.text('already wired up.')]),
            ],
            sub:
                'Binding, validation, dependency injection, realtime, CORS, '
                'exception handling. Not a routing library you assemble a '
                'framework around.',
            center: true,
          ),
          div(classes: 'bento', [
            _codeCard(
              icon: ico.shield,
              title: 'Typed request binding',
              desc:
                  'Query, path, header, cookie and body params are parsed and '
                  'typed before your method runs. A bad request never reaches '
                  'it — it is a 400 with a real message.',
              grammar: hl.dart,
              source: snip.binding,
              width: 'card--half',
              delay: 0,
            ),
            _codeCard(
              icon: ico.layers,
              title: 'Dependency injection built in',
              desc:
                  'Register singletons, lazy singletons and factories on your '
                  'app config. Constructors are injected — including your '
                  'lifecycle components.',
              grammar: hl.dart,
              source: snip.di,
              width: 'card--half',
              delay: 60,
            ),
            _codeCard(
              icon: ico.radio,
              title: 'WebSockets',
              desc: 'Annotate a method. Two-way, receive-only or send-only.',
              grammar: hl.dart,
              source: snip.websocket,
              width: 'card--third',
              delay: 0,
            ),
            _codeCard(
              icon: ico.bolt,
              title: 'Server-sent events',
              desc: 'Return a Stream and Revali handles the rest, cleanup included.',
              grammar: hl.dart,
              source: snip.sse,
              width: 'card--third',
              delay: 60,
            ),
            _codeCard(
              icon: ico.blocks,
              title: 'Write your own construct',
              desc: 'Everything above is a construct. Yours gets the same input.',
              grammar: hl.dart,
              source: snip.construct,
              width: 'card--third',
              delay: 120,
            ),
            _card(
              icon: ico.lock,
              title: 'Access control',
              html:
                  'CORS origins, required and forbidden headers, and pre-flight '
                  'handling, declared with <code>@AllowOrigins</code> and friends.',
              width: 'card--third',
              delay: 0,
            ),
            _card(
              icon: ico.swap,
              title: 'Pipes & transformation',
              html:
                  'Convert a raw <code>String</code> id into a real '
                  '<code>User</code> before your handler sees it, in one annotation.',
              width: 'card--third',
              delay: 60,
            ),
            _card(
              icon: ico.wand,
              title: 'Scaffolding',
              html:
                  '<code>revali create</code> generates controllers, apps, '
                  'pipes, observers and lifecycle components.',
              width: 'card--third',
              delay: 120,
            ),
          ]),
        ]),
      ],
    );
  }

  Component _codeCard({
    required Component icon,
    required String title,
    required String desc,
    required hl.Grammar grammar,
    required String source,
    required String width,
    required int delay,
  }) {
    return div(
      classes: 'card card--code $width',
      attributes: {'data-reveal': '', if (delay > 0) 'style': '--d:${delay}ms'},
      [
        div(classes: 'card__head', [
          span(classes: 'card__ico', [icon]),
          h3([Component.text(title)]),
        ]),
        p([Component.text(desc)]),
        codeBlock(grammar, source),
      ],
    );
  }

  Component _card({
    required Component icon,
    required String title,
    required String html,
    required String width,
    required int delay,
  }) {
    return div(
      classes: 'card $width',
      attributes: {'data-reveal': '', if (delay > 0) 'style': '--d:${delay}ms'},
      [
        span(classes: 'card__ico', [icon]),
        h3([Component.text(title)]),
        p([RawText(html)]),
      ],
    );
  }
}
