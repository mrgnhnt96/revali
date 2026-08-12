import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../src/highlight.dart' as hl;
import '../src/icons.dart' as ico;
import '../src/snippets.dart' as snip;
import '../src/ui.dart';

/// The request lifecycle, in the documented order.
///
/// The third field is the return type that puts a method at that stage — the
/// actual mechanism of `LifecycleComponent`, and the detail that makes the
/// section worth a developer's time.
///
/// Source: content/constructs/revali_server/lifecycle-components/components.md
const _steps = [
  ('Request', 'A request arrives at your server', ''),
  ('Wrapper', 'Wrap the whole request — timing, tracing, transactions', 'WrapperResult'),
  ('Middleware', 'Read it, add to it, short-circuit it', 'MiddlewareResult'),
  ('Guard', 'Let it through, or stop it here', 'GuardResult'),
  ('Interceptor', 'Last look before the handler runs', 'InterceptorPreResult'),
  ('Endpoint', 'Your method. Arguments already parsed and typed', ''),
  ('Interceptor', 'Shape the response on the way out', 'InterceptorPostResult'),
  ('Response', 'Serialized and sent', ''),
];

/// How a request actually flows, and how you hook into it.
///
/// The left column animates as a signal running down the track (driven by
/// `motion.js`); the right shows that the *return type* of a method is what
/// selects its stage — which is the genuinely novel part of the API.
class Lifecycle extends StatelessComponent {
  const Lifecycle();

  @override
  Component build(BuildContext context) {
    return section(
      classes: 'section section--ruled',
      attributes: {'id': 'lifecycle'},
      [
        div(classes: 'shell', [
          sectionHead(
            eyebrow: 'Request lifecycle',
            title: [
              Component.text('The return type '),
              span(classes: 'grad', [Component.text('is the hook.')]),
            ],
            sub:
                'No registration table, no ordering config, no base class per '
                'concern. Write a method on a LifecycleComponent, and what it '
                'returns decides where in the request it runs.',
          ),
          div(classes: 'life', [
            div(
              classes: 'life__track',
              attributes: {'data-reveal': '', 'data-lifecycle': ''},
              [
                for (final (index, (name, desc, ret)) in _steps.indexed)
                  div(
                    classes: 'lstep',
                    attributes: {'data-step': '$index', 'data-on': 'false'},
                    [
                      span(classes: 'lstep__dot', [_dotFor(index)]),
                      span(classes: 'lstep__txt', [
                        strong([Component.text(name)]),
                        span([Component.text(desc)]),
                      ]),
                      if (ret.isNotEmpty) span(classes: 'lstep__ret', [Component.text(ret)]),
                    ],
                  ),
              ],
            ),
            div(
              attributes: {'data-reveal': '', 'style': '--d:100ms'},
              [
                window(
                  title: 'lib/components/session.dart',
                  badge: 'yours',
                  badgeKind: 'yours',
                  live: true,
                  child: codeBlock(hl.dart, snip.lifecycle),
                ),
              ],
            ),
          ]),
        ]),
      ],
    );
  }

  /// The first and last steps are the wire itself; the ones between are the
  /// stages you can occupy, numbered so the track reads as a sequence.
  Component _dotFor(int index) {
    if (index == 0) return ico.arrow;
    if (index == _steps.length - 1) return ico.check;
    return Component.text('$index');
  }
}
