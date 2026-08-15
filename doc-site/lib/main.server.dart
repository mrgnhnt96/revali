/// The entrypoint for the **server** environment.
library;

import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';
import 'package:jaspr_content/components/code_block.dart';
import 'package:jaspr_content/components/github_button.dart';
import 'package:jaspr_content/components/header.dart';
import 'package:jaspr_content/components/image.dart';
import 'package:jaspr_content/components/theme_toggle.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_content/theme.dart';

import 'components/callout.dart';
import 'components/cards.dart';
import 'components/code_file.dart';
import 'components/docs_sidebar.dart';
import 'components/home_link.dart';
import 'components/mermaid.dart';
import 'components/search.dart';
import 'components/section_tabs.dart';
import 'main.server.options.dart';
import 'src/git_lastmod.dart';
import 'src/grammars.dart';
import 'src/navigation.dart';

void main() {
  Jaspr.initializeApp(options: defaultServerOptions);

  runApp(
    // `ContentApp.custom` rather than `ContentApp`, for one reason: the plain
    // constructor hardcodes `dataLoaders` to the filesystem one, and
    // `GitLastModDataLoader` has to be added alongside it so the sitemap can
    // carry a real per-page date. Everything below other than `loaders` and
    // that second data loader is what `ContentApp` would have built anyway —
    // `content/` and `content/_data` are its defaults, spelled out here because
    // `custom` has no defaults to inherit.
    ContentApp.custom(
      loaders: [FilesystemLoader('content')],
      configResolver: PageConfig.all(
        dataLoaders: [FilesystemDataLoader('content/_data'), GitLastModDataLoader()],
        templateEngine: MustacheTemplateEngine(),
        parsers: [MarkdownParser()],
        extensions: [HeadingAnchorsExtension(), TableOfContentsExtension()],
        components: [
          // Order matters. `Mermaid` claims `pre > code.language-mermaid` and
          // has to be offered the node before `CodeBlock`, which would
          // otherwise try to find a "mermaid" grammar and fail the build on a
          // null assertion.
          const Mermaid(),
          CodeBlock(grammars: grammars),
          const Callout(),
          const CodeFile(),
          // `CardGrid` before `Card`: `CustomComponentBase` matches the tag as
          // a *prefix*, so a bare `Card` pattern would swallow `<CardGrid>`.
          // Both patterns are anchored as well, but the order documents the
          // hazard.
          const CardGrid(),
          const Card(),
          const SectionCards(),
          const Hero(),
          Image(zoom: true),
        ],
        layouts: [
          RevaliDocsLayout(
            header: Header(
              title: 'Revali',
              logo: '/images/logo.svg',
              items: [
                // The section switcher sits first so its `margin-right: auto`
                // pushes everything after it to the right of the header.
                const SectionTabs(),
                const DocsSearch(),
                // The one link off this domain and back to the marketing site.
                // Search engines otherwise see a one-way relationship: the
                // landing page links here four times and gets nothing back, so
                // nothing ties the two hosts together as one project.
                const HomeLink(),
                GitHubButton(repo: 'mrgnhnt96/revali'),
                ThemeToggle(),
              ],
            ),
            // The sidebar is generated from `src/navigation.dart` rather than
            // written out here: a hand-written list drifts from `content/`
            // silently — nothing fails when a page is added and not listed.
            sidebar: const DocsSidebar(),
          ),
        ],
        theme: ContentTheme(
          primary: ThemeColor(ThemeColors.indigo.$600, dark: ThemeColors.indigo.$400),
          background: ThemeColor(Colors.white, dark: ThemeColors.zinc.$950),
        ),
      ),
    ),
  );
}

/// [DocsLayout] with breadcrumbs and prev/next links along the reading order in
/// [flatNavigation].
///
/// [buildBody] reproduces `DocsLayout`'s DOM rather than calling `super`,
/// because the upstream layout offers no hook between the sidebar and the page
/// title. The class names are kept identical so the CSS that `super.buildHead`
/// emits still applies — if `jaspr_content` changes its layout markup, this has
/// to follow it.
final class RevaliDocsLayout extends DocsLayout {
  // `header` and `footer` are `DocsLayout`'s own field names, so these
  // super-parameters cannot be renamed without giving up forwarding to them.
  // ignore: avoid_types_as_parameter_names
  const RevaliDocsLayout({super.sidebar, super.header, super.footer});

  @override
  Iterable<Component> buildHead(Page page) sync* {
    yield* super.buildHead(page);
    yield Style(styles: _styles);

    // `PageLayoutBase` reads `image`, `keywords` and the social tags from the
    // *page's* front matter only, so without this a site-wide OG image and
    // canonical URL would have to be repeated in all 96 markdown files.
    final site = page.data.site;
    final pageData = page.data.page;
    final base = site['url'] is String ? site['url']! as String : '';

    if (base.isNotEmpty) {
      final canonical = page.url == '/' ? base : '$base${page.url}';
      yield link(rel: 'canonical', href: canonical);
      yield meta(attributes: {'property': 'og:url'}, content: canonical);
    }
    // The fallbacks are guarded with `when`, not `&&`: in an if-case the whole
    // left-hand side is the matched expression, so `a == null && b case …`
    // tries to pattern-match a bool.
    if (site['description'] case final description? when pageData['description'] == null) {
      yield meta(name: 'description', content: '$description');
      yield meta(attributes: {'property': 'og:description'}, content: '$description');
    }
    // Each page has its own social card, carrying that page's title, rendered
    // by tool/gen_og_cards.dart. The file name is derived from the route here
    // and there by the same rule; the deploy workflow fails if the two ever
    // disagree about what exists.
    //
    // Absolute, not root-relative: every scraper that reads og:image fetches it
    // out of context, and a relative one resolves against their host.
    if (pageData['image'] == null) {
      final card = '/images/og/${ogCardSlug(page.url)}.png';
      yield meta(attributes: {'property': 'og:image'}, content: '$base$card');
      // Twitter reads its own tag first and falls back to og:image; naming it
      // explicitly keeps the two from drifting.
      yield meta(name: 'twitter:image', content: '$base$card');
    }
    if (site['keywords'] case final List<Object?> keywords when pageData['keywords'] == null) {
      yield meta(name: 'keywords', content: keywords.join(', '));
    }
    yield meta(attributes: {'property': 'og:type'}, content: 'website');
    yield meta(attributes: {'property': 'og:site_name'}, content: 'Revali');
    yield meta(name: 'twitter:card', content: 'summary_large_image');
  }

  @override
  Component buildBody(Page page, Component child) {
    final pageData = page.data.page;
    final route = page.url;
    final section = sectionFor(route);
    final group = groupFor(route);
    // The landing page is its own hero; the breadcrumb, `<h1>` and description
    // the layout would stack above it are all already in the content.
    final isLanding = route == '/';

    return div(classes: 'docs', [
      // `this.header`, not `header`: inside a DocsLayout subclass the bare
      // identifier resolves to Jaspr's `<header>` element class instead of the
      // inherited field, and the error it produces says nothing about that.
      if (this.header case final headerComponent?)
        div(
          classes: 'header-container',
          attributes: {if (sidebar != null) 'data-has-sidebar': ''},
          [headerComponent],
        ),
      div(classes: 'main-container', [
        div(classes: 'sidebar-barrier', attributes: {'role': 'button'}, []),
        if (sidebar case final sidebarComponent?)
          div(classes: 'sidebar-container', [sidebarComponent]),
        main_([
          div([
            div(classes: 'content-container', [
              if (!isLanding)
                div(classes: 'content-header', [
                  if (section != null)
                    nav(
                      classes: 'breadcrumbs',
                      attributes: {'aria-label': 'Breadcrumb'},
                      [
                        a(href: section.href, [Component.text(section.title)]),
                        if (group != null) ...[
                          span(classes: 'breadcrumb-sep', [Component.text('/')]),
                          span([Component.text(group.title)]),
                        ],
                      ],
                    ),
                  if (pageData['title'] case final String title) h1([Component.text(title)]),
                  if (pageData['description'] case final String description)
                    p([Component.text(description)]),
                ]),
              child,
              div(classes: 'content-footer', [_PageNav(route: route), ?this.footer]),
            ]),
            aside(classes: 'toc', [
              if (page.data['toc'] case final TableOfContents toc)
                div([
                  h3([Component.text('On this page')]),
                  toc.build(),
                ]),
            ]),
          ]),
        ]),
      ]),
    ]);
  }
}

/// Previous/next links along the reading order defined in [flatNavigation].
final class _PageNav extends StatelessComponent {
  const _PageNav({required this.route});

  final String route;

  @override
  Component build(BuildContext context) {
    final (:previous, :next) = neighborsOf(route);
    if (previous == null && next == null) return const Component.empty();

    return nav(
      classes: 'page-nav',
      attributes: {'aria-label': 'Pagination'},
      [
        if (previous != null)
          a(classes: 'page-nav-link page-nav-prev', href: previous.href, [
            span(classes: 'page-nav-label', [Component.text('Previous')]),
            span(classes: 'page-nav-title', [Component.text(previous.title)]),
          ])
        else
          span([]),
        if (next != null)
          a(classes: 'page-nav-link page-nav-next', href: next.href, [
            span(classes: 'page-nav-label', [Component.text('Next')]),
            span(classes: 'page-nav-title', [Component.text(next.title)]),
          ]),
      ],
    );
  }
}

const _hairline = 'color-mix(in srgb, currentColor 12%, transparent)';
const _hairlineStrong = 'color-mix(in srgb, currentColor 28%, transparent)';

List<StyleRule> get _styles => [
  // `DocsLayout` sets the page description to font-size 1.25rem with an equal
  // line-height, so any description that wraps collides with itself.
  css('.docs .content-header p').styles(opacity: .75, lineHeight: 1.6.em),

  // `Header` gives the logo `flex-basis: 17rem` so it lines up with the sidebar
  // column. On a phone that is two thirds of the viewport, and the search
  // button ends up rendered on top of the word "Revali". Below the sidebar
  // breakpoint the logo should just be as wide as it is.
  css.media(MediaQuery.all(maxWidth: 1023.px), [
    css('.docs .header .header-title').styles(flex: Flex(basis: Unit.auto, shrink: 1)),
    css('.docs .header').styles(gap: Gap.column(.5.rem)),
  ]),
  // Of the three things on the right, the repo link is the one a reader on a
  // phone needs least, and dropping it is what buys the search box its room.
  css.media(MediaQuery.all(maxWidth: 639.px), [
    css('.docs .header .github-button').styles(display: Display.none),
    css('.docs .header .header-title span').styles(
      overflow: Overflow.hidden,
      textOverflow: TextOverflow.ellipsis,
      whiteSpace: WhiteSpace.noWrap,
    ),
  ]),

  css('.breadcrumbs', [
    css('&').styles(
      display: Display.flex,
      margin: Margin.only(bottom: .625.rem),
      opacity: .6,
      gap: Gap.column(.5.rem),
      fontSize: .8125.rem,
    ),
    css('a').styles(color: Color('inherit'), textDecoration: TextDecoration.none),
    css('a:hover').styles(textDecoration: TextDecoration(line: TextDecorationLine.underline)),
    css('.breadcrumb-sep').styles(opacity: .5),
  ]),

  css('.page-nav', [
    css('&').styles(
      display: Display.flex,
      padding: Padding.only(top: 1.5.rem),
      margin: Margin.only(top: 3.rem),
      border: Border.only(
        top: BorderSide(width: 1.px, color: Color(_hairline)),
      ),
      justifyContent: JustifyContent.spaceBetween,
      gap: Gap.column(1.rem),
    ),
    css('.page-nav-link', [
      css('&').styles(
        display: Display.flex,
        maxWidth: 48.percent,
        padding: Padding.symmetric(horizontal: 1.rem, vertical: .75.rem),
        border: Border.all(width: 1.px, color: Color(_hairline)),
        radius: BorderRadius.circular(10.px),
        transition: Transition('all', duration: 150.ms, curve: Curve.easeInOut),
        flexDirection: FlexDirection.column,
        gap: Gap.row(.125.rem),
        color: Color('inherit'),
        textDecoration: TextDecoration.none,
      ),
      css('&:hover').styles(
        border: Border.all(width: 1.px, color: Color(_hairlineStrong)),
        backgroundColor: Color('color-mix(in srgb, currentColor 4%, transparent)'),
      ),
      css('.page-nav-label').styles(
        opacity: .55,
        fontSize: .6875.rem,
        textTransform: TextTransform.upperCase,
        letterSpacing: .04.em,
      ),
      css(
        '.page-nav-title',
      ).styles(color: ContentColors.primary, fontSize: .9375.rem, fontWeight: FontWeight.w600),
    ]),
    css('.page-nav-next').styles(
      margin: Margin.only(left: Unit.auto),
      textAlign: TextAlign.right,
    ),
  ]),

  // Tables come out of markdown unstyled, and this site has 30-odd of them
  // listing annotation parameters — the one content type where the default is
  // genuinely unreadable.
  css('.content-container table', [
    css('&').styles(
      width: 100.percent,
      margin: Margin.symmetric(vertical: 1.25.rem),
      border: Border.all(width: 1.px, color: Color(_hairline)),
      radius: BorderRadius.circular(.5.rem),
      fontSize: .875.rem,
      // `separate` so the radius above is not clipped away by collapsed
      // borders; the row separators below are drawn per-cell instead.
      raw: {'display': 'table', 'border-collapse': 'separate', 'border-spacing': '0'},
    ),
    css('th, td').styles(
      padding: Padding.symmetric(horizontal: .875.rem, vertical: .5.rem),
      textAlign: TextAlign.left,
    ),
    css('thead th').styles(
      border: Border.only(
        bottom: BorderSide(width: 1.px, color: Color(_hairline)),
      ),
      fontWeight: FontWeight.w600,
      backgroundColor: Color('color-mix(in srgb, currentColor 4%, transparent)'),
    ),
    css('tbody tr + tr td').styles(
      border: Border.only(
        top: BorderSide(width: 1.px, color: Color(_hairline)),
      ),
    ),
  ]),
];

/// The file name of a route's social card, under `web/images/og/`.
///
/// Must stay in step with `ogCardSlug` in tool/gen_og_cards.dart -- that tool
/// writes the files this names. Deliberately dumb: `/revali/cli/routes` becomes
/// `revali-cli-routes`.
String ogCardSlug(String route) {
  final trimmed = route.replaceAll(RegExp(r'^/|/$'), '');
  if (trimmed.isEmpty) return 'index';
  return trimmed.replaceAll('/', '-');
}
