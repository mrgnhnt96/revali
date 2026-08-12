import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../src/highlight.dart' as hl;
import '../src/icons.dart' as ico;
import '../src/snippets.dart' as snip;
import '../src/ui.dart';

/// Three steps to a running server, and the closing call to action.
///
/// Deliberately the last thing on the page and deliberately short: a visitor
/// who has scrolled this far has already decided, and what they want now is
/// the command to paste.
class Quickstart extends StatelessComponent {
  const Quickstart();

  @override
  Component build(BuildContext context) {
    return section(
      classes: 'section section--ruled',
      attributes: {'id': 'start'},
      [
        div(classes: 'shell', [
          sectionHead(
            eyebrow: 'Quickstart',
            title: [
              Component.text('Running in '),
              span(classes: 'grad', [Component.text('under a minute.')]),
            ],
            center: true,
          ),
          div(classes: 'qs', [
            _step(1, 'Add the packages', hl.shell, snip.quickstartInstall, 0),
            _step(2, 'Write a controller', hl.dart, snip.quickstartController, 80),
            _step(3, 'Run it', hl.shell, snip.quickstartRun, 160),
          ]),
          const _Cta(),
        ]),
      ],
    );
  }

  Component _step(int n, String title, hl.Grammar grammar, String source, int delay) {
    return div(
      classes: 'qstep',
      attributes: {'data-reveal': '', if (delay > 0) 'style': '--d:${delay}ms'},
      [
        div(classes: 'qstep__head', [
          span(classes: 'qstep__n', [Component.text('$n')]),
          strong([Component.text(title)]),
          copyButton(source.trim()),
        ]),
        codeBlock(grammar, source),
      ],
    );
  }
}

class _Cta extends StatelessComponent {
  const _Cta();

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'cta',
      attributes: {'data-reveal': '', 'style': 'margin-top:clamp(3rem,6vw,5rem)'},
      [
        h2([
          Component.text('Stop writing the parts '),
          span(classes: 'grad', [Component.text('a compiler could write.')]),
        ]),
        p([
          Component.text(
            'Revali is open source and MIT licensed. Your annotations '
            'are the spec — everything else is generated.',
          ),
        ]),
        div(classes: 'cta__cmd', [
          span(classes: 'term__prompt', [Component.text(r'$')]),
          span(classes: 'code', [Component.text(snip.installCommand)]),
          copyButton(snip.installCommand),
        ]),
        div(classes: 'cta__row', [
          a(
            classes: 'btn btn--primary btn--lg',
            href: 'https://docs.revali.dev/revali/getting-started/installation',
            [Component.text('Read the docs'), ico.arrow],
          ),
          a(
            classes: 'btn btn--ghost btn--lg',
            href: 'https://github.com/mrgnhnt96/revali',
            attributes: {'target': '_blank', 'rel': 'noopener'},
            [ico.github, Component.text('GitHub')],
          ),
        ]),
      ],
    );
  }
}
