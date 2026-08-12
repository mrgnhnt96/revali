import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../src/icons.dart' as ico;
import '../src/ui.dart';

/// The dev loop, shown as the terminal you actually sit in front of.
///
/// The transcript is the documented status board from
/// content/revali/cli/dev.md — same wording, same hotkeys. A fabricated
/// terminal is the fastest way to lose a developer's trust, since they will
/// run the command within the minute.
class Loop extends StatelessComponent {
  const Loop();

  @override
  Component build(BuildContext context) {
    return section(
      classes: 'section section--ruled',
      attributes: {'id': 'loop'},
      [
        div(classes: 'shell', [
          sectionHead(
            eyebrow: 'The dev loop',
            title: [
              Component.text('One command. '),
              span(classes: 'grad', [Component.text('Then just write code.')]),
            ],
            sub:
                'No build_runner in a second terminal, no codegen step to '
                'remember, no restart to sit through. Save the file; the routes '
                'are regenerated and the server hot reloads.',
            center: true,
          ),
          div(classes: 'life', [
            div(
              attributes: {'data-reveal': ''},
              [
                window(
                  title: 'zsh — revali dev',
                  icon: ico.terminal,
                  live: true,
                  child: div(classes: 'term', [
                    _cmd('dart run revali dev'),
                    _out('12:34:56 PM ', 'term__out', suffix: '[READY]', suffixClass: 'term__ok'),
                    _link('Serving at ', 'http://localhost:8080/api'),
                    _keys(),
                    _blank(),
                    _out('/users', 'term__out'),
                    _out('GET -> /users/', 'term__out'),
                    _blank(),
                    // The moment the section is about: an edit, and the reload it
                    // causes, with nothing typed in between.
                    _out('12:35:02 PM ', 'term__out', suffix: '[RELOAD]', suffixClass: 'term__key'),
                    _out('routes/users_controller.dart changed', 'term__out'),
                    _link('Serving at ', 'http://localhost:8080/api'),
                    div(classes: 'term__line', [
                      span(classes: 'term__prompt', [Component.text(r'$')]),
                      span(classes: 'term__cursor', []),
                    ]),
                  ]),
                ),
              ],
            ),
            div(
              classes: 'bento',
              attributes: {'data-reveal': '', 'style': '--d:100ms'},
              [
                _tip(
                  ico.refresh,
                  'Hot reload',
                  'Changes in <code>routes/</code> and '
                      '<code>lib/components/</code> reload the running server in place.',
                ),
                _tip(
                  ico.bug,
                  'Real debugging',
                  'A Dart VM service is running, so '
                      'attach your IDE and set breakpoints in generated code too.',
                ),
                _tip(
                  ico.route,
                  'See your routes',
                  '<code>revali routes</code> prints '
                      'the route table straight from the generated manifest.',
                ),
                _tip(
                  ico.stethoscope,
                  'Diagnose it',
                  '<code>revali doctor</code> '
                      'checks the kernel, constructs and generated output.',
                ),
              ],
            ),
          ]),
        ]),
      ],
    );
  }

  Component _cmd(String text) {
    return div(classes: 'term__line', [
      span(classes: 'term__prompt', [Component.text(r'$')]),
      span([Component.text(text)]),
    ]);
  }

  Component _out(String text, String cls, {String? suffix, String? suffixClass}) {
    return div(classes: 'term__line', [
      span(classes: cls, [Component.text(text)]),
      if (suffix != null) span(classes: suffixClass ?? '', [Component.text(suffix)]),
    ]);
  }

  Component _link(String prefix, String url) {
    return div(classes: 'term__line', [
      span(classes: 'term__out', [Component.text(prefix)]),
      span(classes: 'term__url', [Component.text(url)]),
    ]);
  }

  Component _keys() {
    return div(classes: 'term__line', [
      span(classes: 'term__out', [Component.text('Press: ')]),
      span(classes: 'term__key', [Component.text('r')]),
      span(classes: 'term__out', [Component.text(' reload, ')]),
      span(classes: 'term__key', [Component.text('c')]),
      span(classes: 'term__out', [Component.text(' clear, ')]),
      span(classes: 'term__key', [Component.text('q')]),
      span(classes: 'term__out', [Component.text(' quit')]),
    ]);
  }

  Component _blank() => div(classes: 'term__line', [Component.text(' ')]);

  /// A small feature card. [html] carries inline `<code>` markup, which is the
  /// one reason these use `raw` rather than plain text nodes — the strings are
  /// literals in this file, never user input.
  Component _tip(Component icon, String title, String html) {
    return div(classes: 'card card--half', [
      span(classes: 'card__ico', [icon]),
      h3([Component.text(title)]),
      p([RawText(html)]),
    ]);
  }
}
