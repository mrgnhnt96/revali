/// Landing-page building blocks: `<Hero>`, `<CardGrid>`, `<Card>` and
/// `<SectionCards />`.
///
/// These exist so `content/index.md` stays markdown. The alternative — a
/// hand-built Dart landing page — is what the Docusaurus site had, and it drifted
/// from the docs it was advertising because nothing connected the two.
///
/// [SectionCards] is the important one: it renders one card per [NavSection]
/// from `lib/src/navigation.dart`, so the landing page's index of the site
/// cannot fall out of step with the sidebar.
///
/// As with [Callout], blank lines inside the tags are mandatory — see that
/// file's note on why.
library;

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_content/theme.dart';

import '../src/navigation.dart';

/// `<CardGrid columns="3">` — a responsive grid of [Card]s.
final class CardGrid extends CustomComponentBase {
  const CardGrid();

  @override
  Pattern get pattern => RegExp(r'^CardGrid$');

  @override
  Component apply(String name, Map<String, String> attributes, Component? child) {
    final columns = int.tryParse(attributes['columns'] ?? '') ?? 2;
    return Component.fragment([
      Document.head(children: [Style(styles: _styles)]),
      div(
        classes: 'card-grid',
        // Below the breakpoint in `_styles` this is overridden to one column;
        // above it, the author's choice wins.
        styles: Styles(raw: {'--card-columns': '$columns'}),
        [?child],
      ),
    ]);
  }
}

/// `<Card title href icon badge>` — a tile, linked when `href` is given.
final class Card extends CustomComponentBase {
  const Card();

  @override
  Pattern get pattern => RegExp(r'^Card$');

  @override
  Component apply(String name, Map<String, String> attributes, Component? child) {
    final href = attributes['href'];
    final body = [
      div(classes: 'card-head', [
        if (CardIcons.of(attributes['icon']) case final icon?)
          span(classes: 'card-icon', [RawText(icon)]),
        span(classes: 'card-title', [Component.text(attributes['title'] ?? '')]),
        if (attributes['badge'] case final badge?)
          span(classes: 'card-badge', [Component.text(badge)]),
      ]),
      if (child != null) div(classes: 'card-body', [child]),
      if (href != null) span(classes: 'card-arrow', [RawText(_arrowIcon)]),
    ];

    return Component.fragment([
      Document.head(children: [Style(styles: _styles)]),
      if (href != null)
        a(href: href, classes: 'card card-link', body)
      else
        div(classes: 'card', body),
    ]);
  }
}

/// `<SectionCards />` — one card per [NavSection], generated from navigation.
final class SectionCards extends CustomComponentBase {
  const SectionCards();

  @override
  Pattern get pattern => RegExp(r'^SectionCards$');

  @override
  Component apply(String name, Map<String, String> attributes, Component? child) {
    return Component.fragment([
      Document.head(children: [Style(styles: _styles)]),
      div(classes: 'card-grid section-cards', styles: Styles(raw: {'--card-columns': '3'}), [
        for (final section in sections)
          a(href: section.href, classes: 'card card-link', [
            div(classes: 'card-head', [
              span(classes: 'card-icon', [RawText(section.icon)]),
              span(classes: 'card-title', [Component.text(section.title)]),
            ]),
            div(classes: 'card-body', [
              p([Component.text(section.summary)]),
            ]),
            // A card for a whole section is worth more than its one-liner:
            // listing what is inside is what tells a reader whether it is the
            // section they want.
            ul(classes: 'card-contents', [
              for (final group in section.entries.whereType<NavGroup>().take(4))
                li([Component.text(group.title)]),
            ]),
            span(classes: 'card-arrow', [RawText(_arrowIcon)]),
          ]),
      ]),
    ]);
  }
}

/// `<Hero>` — the landing page's opening block.
///
/// Its child is the code sample shown beside the headline; everything else
/// comes in as attributes.
///
/// Two constraints the markdown has to respect, both of which fail silently:
///
/// - **The opening tag must be on one line.** `Hero` is not a known HTML tag,
///   so `package:markdown` only treats it as an HTML *block* under CommonMark's
///   rule 7, which requires the complete open tag on a single line. Split over
///   several lines it becomes inline HTML inside a paragraph instead, and the
///   code block below it stops being its child.
/// - **Attribute names must be lowercase or hyphenated.** The HTML parser
///   downcases them, so `primaryLabel` arrives as `primarylabel`. Hyphens
///   survive, so that is what these are named.
final class Hero extends CustomComponentBase {
  const Hero();

  @override
  Pattern get pattern => RegExp(r'^Hero$');

  @override
  Component apply(String name, Map<String, String> attributes, Component? child) {
    return Component.fragment([
      Document.head(children: [Style(styles: _styles)]),
      section(classes: 'hero', [
        div(classes: 'hero-text', [
          h1([Component.text(attributes['headline'] ?? '')]),
          p(classes: 'hero-tagline', [Component.text(attributes['tagline'] ?? '')]),
          div(classes: 'hero-actions', [
            if (attributes['primary-href'] case final href?)
              a(href: href, classes: 'hero-button primary', [
                Component.text(attributes['primary-label'] ?? 'Get started'),
                RawText(_arrowIcon),
              ]),
            if (attributes['secondary-href'] case final href?)
              a(href: href, classes: 'hero-button secondary', [
                Component.text(attributes['secondary-label'] ?? 'GitHub'),
              ]),
          ]),
        ]),
        if (child != null) div(classes: 'hero-code', [child]),
      ]),
    ]);
  }
}

/// Icons addressable by name from markdown, e.g. `<Card icon="rocket">`.
///
/// Reuses [NavIcons] so a card and its sidebar group cannot disagree, plus the
/// two the landing page needs that nothing navigates to.
abstract final class CardIcons {
  static String? of(String? name) => switch (name) {
    'rocket' => NavIcons.rocket,
    'blocks' => NavIcons.blocks,
    'server' => NavIcons.server,
    'plug' => NavIcons.plug,
    'terminal' => NavIcons.terminal,
    'book' => NavIcons.book,
    'wrench' => NavIcons.wrench,
    'container' => NavIcons.container,
    'file-text' => NavIcons.fileText,
    'sliders' => NavIcons.sliders,
    'dart' => dart,
    _ => null,
  };

  /// The Dart logo mark, simplified to two strokes so it reads at 16px and
  /// inherits `currentColor` like every other icon here.
  static const dart =
      '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" '
      'stroke="currentColor" stroke-width="2" stroke-linejoin="round" aria-hidden="true">'
      '<path d="M8.5 2 2 8.5V15l7 7h6.5L22 15.5V9z"/><path d="m9 22 6.5-6.5V9L9 15.5z"/></svg>';
}

const _arrowIcon =
    '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" '
    'stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">'
    '<path d="M5 12h14"/><path d="m12 5 7 7-7 7"/></svg>';

const _hairline = 'color-mix(in srgb, currentColor 12%, transparent)';
const _hairlineStrong = 'color-mix(in srgb, currentColor 26%, transparent)';

List<StyleRule> get _styles => [
  css('.card-grid', [
    css('&').styles(
      display: Display.grid,
      margin: Margin.symmetric(vertical: 1.5.rem),
      gap: Gap.all(.875.rem),
      raw: {'grid-template-columns': '1fr'},
    ),
    css.media(MediaQuery.all(minWidth: 640.px), [
      css(
        '&',
      ).styles(raw: {'grid-template-columns': 'repeat(var(--card-columns, 2), minmax(0, 1fr))'}),
    ]),
  ]),

  css('.card', [
    css('&').styles(
      position: Position.relative(),
      display: Display.flex,
      padding: Padding.all(1.125.rem),
      border: Border.all(width: 1.px, color: Color(_hairline)),
      radius: BorderRadius.circular(.75.rem),
      transition: Transition('all', duration: 150.ms, curve: Curve.easeInOut),
      flexDirection: FlexDirection.column,
      gap: Gap.row(.5.rem),
      color: Color('inherit'),
      textDecoration: TextDecoration.none,
    ),
    css('&.card-link:hover').styles(
      border: Border.all(width: 1.px, color: Color(_hairlineStrong)),
      transform: Transform.translate(y: (-2).px),
      backgroundColor: Color('color-mix(in srgb, currentColor 4%, transparent)'),
    ),
    css('.card-head', [
      css(
        '&',
      ).styles(display: Display.flex, alignItems: AlignItems.center, gap: Gap.column(.5.rem)),
      css(
        '.card-icon',
      ).styles(display: Display.flex, color: ContentColors.primary, flex: Flex(shrink: 0)),
      css('.card-title').styles(fontSize: 1.rem, fontWeight: FontWeight.w600),
      css('.card-badge').styles(
        padding: Padding.symmetric(horizontal: .375.rem),
        radius: BorderRadius.circular(999.px),
        color: ContentColors.primary,
        fontSize: .625.rem,
        fontWeight: FontWeight.w700,
        textTransform: TextTransform.upperCase,
        letterSpacing: .03.em,
        backgroundColor: Color('color-mix(in srgb, currentColor 12%, transparent)'),
      ),
    ]),
    css('.card-body', [
      css('&').styles(opacity: .75, fontSize: .875.rem, lineHeight: 1.55.em),
      css('> :first-child').styles(margin: Margin.only(top: Unit.zero)),
      css('> :last-child').styles(margin: Margin.only(bottom: Unit.zero)),
    ]),
    css('.card-contents', [
      css('&').styles(
        display: Display.flex,
        padding: Padding.only(top: .75.rem),
        margin: Margin.only(top: Unit.auto),
        border: Border.only(
          top: BorderSide(width: 1.px, color: Color(_hairline)),
        ),
        flexWrap: FlexWrap.wrap,
        gap: Gap.all(.3125.rem),
        listStyle: ListStyle.none,
        fontSize: .6875.rem,
      ),
      // Pills, not a middot-separated run. These wrap at unpredictable points
      // inside a narrow card, and a separator character then dangles at the end
      // of a line with nothing after it.
      css('li').styles(
        padding: Padding.symmetric(horizontal: .5.rem, vertical: .1875.rem),
        radius: BorderRadius.circular(999.px),
        opacity: .75,
        whiteSpace: WhiteSpace.noWrap,
        backgroundColor: Color('color-mix(in srgb, currentColor 8%, transparent)'),
      ),
    ]),
    css('.card-arrow').styles(
      position: Position.absolute(top: 1.125.rem, right: 1.125.rem),
      display: Display.flex,
      opacity: 0,
      transition: Transition('all', duration: 150.ms, curve: Curve.easeInOut),
      color: ContentColors.primary,
    ),
    css(
      '&.card-link:hover .card-arrow',
    ).styles(opacity: .9, transform: Transform.translate(x: 2.px)),
  ]),

  css('.hero', [
    css('&').styles(
      display: Display.grid,
      padding: Padding.only(bottom: 2.rem),
      margin: Margin.only(bottom: 1.rem),
      border: Border.only(
        bottom: BorderSide(width: 1.px, color: Color(_hairline)),
      ),
      gap: Gap.all(2.rem),
      alignItems: AlignItems.center,
      raw: {'grid-template-columns': '1fr'},
    ),
    css.media(MediaQuery.all(minWidth: 900.px), [
      css('&').styles(raw: {'grid-template-columns': 'minmax(0, 5fr) minmax(0, 6fr)'}),
    ]),

    css('h1').styles(
      margin: Margin.only(top: Unit.zero, bottom: .75.rem),
      fontSize: 2.25.rem,
      fontWeight: FontWeight.w800,
      lineHeight: 1.1.em,
      letterSpacing: (-0.02).em,
    ),
    css('.hero-tagline').styles(
      margin: Margin.only(bottom: 1.5.rem),
      opacity: .75,
      fontSize: 1.0625.rem,
      lineHeight: 1.6.em,
    ),
    css(
      '.hero-actions',
    ).styles(display: Display.flex, flexWrap: FlexWrap.wrap, gap: Gap.all(.625.rem)),
    css('.hero-button', [
      css('&').styles(
        display: Display.inlineFlex,
        padding: Padding.symmetric(horizontal: 1.125.rem, vertical: .625.rem),
        radius: BorderRadius.circular(.5.rem),
        transition: Transition('all', duration: 150.ms, curve: Curve.easeInOut),
        alignItems: AlignItems.center,
        gap: Gap.column(.5.rem),
        fontSize: .9375.rem,
        fontWeight: FontWeight.w600,
        textDecoration: TextDecoration.none,
      ),
      css('&.primary').styles(
        border: Border.all(width: 1.px, color: ContentColors.primary),
        color: ContentColors.background,
        backgroundColor: ContentColors.primary,
      ),
      css('&.primary:hover').styles(raw: {'filter': 'brightness(1.1)'}),
      css('&.secondary').styles(
        border: Border.all(width: 1.px, color: Color(_hairlineStrong)),
        color: Color('inherit'),
      ),
      css(
        '&.secondary:hover',
      ).styles(backgroundColor: Color('color-mix(in srgb, currentColor 6%, transparent)')),
    ]),
    // The hero's code sample is decoration, not something to read line by line;
    // shrink it so a ten-line controller fits without scrolling.
    css('.hero-code', [
      css('&').styles(minWidth: Unit.zero),
      css('pre').styles(
        margin: Margin.zero,
        // A grid track defaults to `min-width: auto`, so without the `minWidth`
        // above plus this the code column refuses to shrink and its longest
        // line is simply clipped off the right of the card.
        overflow: Overflow.only(x: Overflow.auto),
        fontSize: .8125.rem,
      ),
      css('.code-block').styles(margin: Margin.zero),
    ]),
  ]),
];
