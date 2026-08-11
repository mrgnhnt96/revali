/// The header's section switcher: Revali / Constructs / Create Constructs.
///
/// These are the three [NavSection]s from `lib/src/navigation.dart`, and they
/// are the top level of the site's navigation — the sidebar shows one section
/// at a time, so this is how a reader moves between them. Equivalent to the
/// three `docSidebar` navbar items the Docusaurus site had.
///
/// A plain list of links rather than a `@client` component: which tab is active
/// is knowable at build time from the page's own url, and a static site should
/// not need JavaScript to underline a link.
library;

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_content/theme.dart';

import '../src/navigation.dart';

/// Links to each [NavSection], with the one containing the current page marked.
class SectionTabs extends StatelessComponent {
  const SectionTabs({super.key});

  @override
  Component build(BuildContext context) {
    final active = sectionFor(context.page.url);

    return Component.fragment([
      Document.head(children: [Style(styles: _styles)]),
      nav(
        classes: 'section-tabs',
        attributes: {'aria-label': 'Documentation sections'},
        [
          for (final section in sections)
            a(
              href: section.href,
              classes: identical(section, active) ? 'section-tab active' : 'section-tab',
              attributes: {
                'title': section.summary,
                if (identical(section, active)) 'aria-current': 'true',
              },
              [Component.text(section.title)],
            ),
        ],
      ),
    ]);
  }
}

List<StyleRule> get _styles => [
  css('.section-tabs', [
    css('&').styles(
      // Pushes the search box and theme toggle to the far right, leaving the
      // tabs beside the logo. `Header` right-aligns everything in `items`.
      display: Display.none,
      margin: Margin.only(right: Unit.auto),
      gap: Gap.column(.25.rem),
    ),
    // Below this the header has no room for three labels beside the logo and
    // the search box; the sidebar shows the section name instead.
    css.media(MediaQuery.all(minWidth: 1024.px), [css('&').styles(display: Display.flex)]),

    css('.section-tab', [
      css('&').styles(
        display: Display.flex,
        padding: Padding.symmetric(horizontal: .75.rem, vertical: .375.rem),
        radius: BorderRadius.circular(.5.rem),
        opacity: .7,
        transition: Transition('all', duration: 150.ms, curve: Curve.easeInOut),
        alignItems: AlignItems.center,
        color: Color('inherit'),
        fontSize: .875.rem,
        fontWeight: FontWeight.w500,
        textDecoration: TextDecoration.none,
        whiteSpace: WhiteSpace.noWrap,
      ),
      css('&:hover').styles(
        opacity: 1,
        backgroundColor: Color('color-mix(in srgb, currentColor 6%, transparent)'),
      ),
      css('&.active').styles(
        opacity: 1,
        color: ContentColors.primary,
        fontWeight: FontWeight.w600,
        backgroundColor: Color('color-mix(in srgb, currentColor 10%, transparent)'),
      ),
    ]),
  ]),
];
