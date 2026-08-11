/// Renders ```` ```mermaid ```` fences as diagrams.
///
/// Seven pages carry one. They have to be intercepted *before* `CodeBlock` in
/// `ContentApp(components:)`: `CodeBlock` looks the language up in the
/// highlighter's grammar cache with a null assertion, so an unregistered
/// language is a crash at build time rather than an unhighlighted block.
///
/// Mermaid itself runs in the browser, from a CDN, and only on pages that have
/// a diagram — the library is ~3 MB, which is not worth vendoring for seven
/// figures. With JavaScript off (or the CDN blocked) the diagram source stays
/// visible as preformatted text rather than the page losing a section.
library;

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';

/// Pinned to a major version so a mermaid release cannot change seven diagrams
/// on this site without a commit here.
const _mermaidUrl = 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';

/// Replaces a mermaid code fence with a `<pre class="mermaid">` for the
/// client-side renderer to pick up.
final class Mermaid extends CustomComponent {
  const Mermaid() : super.base();

  @override
  Component? create(Node node, NodesBuilder builder) {
    if (node case ElementNode(
      tag: 'pre',
      children: [ElementNode(tag: 'code', :final children, :final attributes)],
    ) when attributes['class'] == 'language-mermaid') {
      return _MermaidDiagram(source: children?.map((child) => child.innerText).join() ?? '');
    }
    return null;
  }
}

final class _MermaidDiagram extends StatelessComponent {
  const _MermaidDiagram({required this.source});

  final String source;

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      Document.head(
        children: [
          Style(styles: _styles),
          // `content:`, not children — Jaspr's `script` takes no positional
          // children, and `attributes` is how the `type` gets set.
          script(attributes: const {'type': 'module'}, content: _bootstrap),
        ],
      ),
      // `figure`, not a bare `pre`: a diagram is a figure, and it gives the
      // horizontal scroll a place to live on a phone.
      figure(classes: 'mermaid-figure', [
        pre(classes: 'mermaid', [Component.text(source)]),
      ]),
    ]);
  }
}

/// Loads mermaid, renders every diagram, and re-renders when the theme changes.
///
/// The re-render is the part that is easy to miss: mermaid bakes its colors
/// into the generated SVG, so a diagram rendered in light mode stays light
/// after the theme toggle unless it is drawn again from the original source.
/// The source is stashed on the node before the first render for exactly that.
const _bootstrap =
    '''
import mermaid from '$_mermaidUrl';

const nodes = () => document.querySelectorAll('pre.mermaid');
const isDark = () => document.documentElement.dataset.theme === 'dark';

for (const node of nodes()) node.dataset.source = node.textContent;

let rendering = false;
async function render() {
  if (rendering) return;
  rendering = true;
  try {
    mermaid.initialize({
      startOnLoad: false,
      securityLevel: 'strict',
      theme: isDark() ? 'dark' : 'neutral',
      fontFamily: 'inherit',
    });
    for (const node of nodes()) {
      node.removeAttribute('data-processed');
      node.innerHTML = node.dataset.source;
    }
    await mermaid.run({ nodes: nodes() });
  } catch (error) {
    // A malformed diagram should cost its own figure, not the whole page.
    console.error('mermaid:', error);
  } finally {
    rendering = false;
  }
}

render();
new MutationObserver(render).observe(document.documentElement, {
  attributes: true,
  attributeFilter: ['data-theme'],
});
''';

List<StyleRule> get _styles => [
  css('.mermaid-figure', [
    css('&').styles(
      padding: Padding.symmetric(horizontal: 1.rem, vertical: 1.25.rem),
      margin: Margin.symmetric(vertical: 1.5.rem),
      border: Border.all(
        width: 1.px,
        color: Color('color-mix(in srgb, currentColor 12%, transparent)'),
      ),
      radius: BorderRadius.circular(.75.rem),
      overflow: Overflow.only(x: Overflow.auto),
    ),
    css('pre.mermaid', [
      css('&').styles(
        display: Display.flex,
        padding: Padding.zero,
        margin: Margin.zero,
        justifyContent: JustifyContent.center,
        // Until mermaid replaces the contents this is the diagram source; wrap
        // it like source rather than letting it stretch the page.
        whiteSpace: WhiteSpace.preWrap,
        backgroundColor: Colors.transparent,
      ),
      css('svg').styles(maxWidth: 100.percent, height: Unit.auto),
    ]),
  ]),
];
