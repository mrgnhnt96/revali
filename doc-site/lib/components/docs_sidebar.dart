/// The docs sidebar: collapsible, icon-labelled groups driven by
/// `lib/src/navigation.dart`.
///
/// Replaces `jaspr_content`'s flat [Sidebar], which renders every group
/// expanded. With 96 pages that is a long scroll with no landmarks; collapsing
/// all but the ancestors of the current page turns it into a short menu.
///
/// Only the *active section's* entries are rendered — the header's section tabs
/// switch between Revali, Constructs and Create Constructs, and a reader is
/// only ever inside one of them. All three at once was 96 links in one column.
///
/// Built on `<details>`/`<summary>` so it collapses without JavaScript and is
/// keyboard- and screen-reader-navigable for free.
library;

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_content/theme.dart';

import '../src/navigation.dart';

/// A sidebar rendered from the [NavSection] that owns the current route.
class DocsSidebar extends StatelessComponent {
  const DocsSidebar({this.currentRoute, super.key});

  /// The route to mark active. Defaults to the current page's url.
  final String? currentRoute;

  @override
  Component build(BuildContext context) {
    final route = currentRoute ?? context.page.url;
    // The landing page belongs to no section; show the first one rather than an
    // empty column, so the sidebar is never a blank rail.
    final section = sectionFor(route) ?? sections.first;

    return Component.fragment([
      Document.head(children: [Style(styles: _styles)]),
      nav(
        classes: 'docs-sidebar',
        attributes: {'aria-label': section.title},
        [
          button(
            classes: 'sidebar-close',
            attributes: {'aria-label': 'Close navigation', 'type': 'button'},
            [RawText(_closeIcon)],
          ),
          // Repeated from the header, where the tabs collapse into a menu below
          // 1024px. Without it there is no way to tell which section you are in
          // on a phone.
          div(classes: 'docs-sidebar-section', [
            span(classes: 'docs-sidebar-section-icon', [RawText(section.icon)]),
            span([Component.text(section.title)]),
          ]),
          ul(classes: 'docs-sidebar-list', [
            for (final entry in section.entries) _entry(entry, route, depth: 0),
          ]),
        ],
      ),
    ]);
  }

  Component _entry(NavEntry entry, String route, {required int depth}) => switch (entry) {
    NavItem() => _link(entry, route),
    NavGroup() => _group(entry, route, depth: depth),
  };

  Component _group(NavGroup group, String route, {required int depth}) {
    return li(classes: 'docs-sidebar-group-item', [
      details(
        classes: depth == 0 ? 'docs-sidebar-group' : 'docs-sidebar-group nested',
        // Open the groups on the path to the current page. On a section's own
        // overview page nothing is active, so the first group opens as a
        // starting point rather than presenting a fully collapsed menu.
        open: _contains(group, route) || (_isSectionRoot(route) && _isFirstGroup(group, route)),
        [
          summary(classes: 'docs-sidebar-summary', [
            if (group.icon case final icon?) span(classes: 'docs-sidebar-icon', [RawText(icon)]),
            span(classes: 'docs-sidebar-title', [Component.text(group.title)]),
            span(classes: 'docs-sidebar-chevron', [RawText(_chevronIcon)]),
          ]),
          ul([for (final child in group.entries) _entry(child, route, depth: depth + 1)]),
        ],
      ),
    ]);
  }

  Component _link(NavItem item, String route) {
    final isActive = item.href == route;
    return li([
      a(
        href: item.href,
        classes: isActive ? 'docs-sidebar-link active' : 'docs-sidebar-link',
        attributes: {if (isActive) 'aria-current': 'page'},
        [
          span([Component.text(item.title)]),
          if (item.badge case final badge?)
            span(classes: 'docs-sidebar-badge', [Component.text(badge)]),
        ],
      ),
    ]);
  }

  /// Whether [route] is somewhere inside [group], at any depth.
  static bool _contains(NavGroup group, String route) =>
      itemsOf(group.entries).any((item) => item.href == route);

  static bool _isSectionRoot(String route) => sections.any((entry) => entry.href == route);

  static bool _isFirstGroup(NavGroup group, String route) {
    // Not named `section` — that identifier resolves to Jaspr's `<section>`
    // element class here, and the lint that catches it is easy to silence and
    // then be confused by.
    final owner = sectionFor(route);
    if (owner == null) return false;
    return identical(group, owner.entries.whereType<NavGroup>().firstOrNull);
  }
}

const _chevronIcon =
    '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" '
    'stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">'
    '<path d="m9 18 6-6-6-6"/></svg>';

const _closeIcon =
    '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" '
    'stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">'
    '<path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>';

const _hairline = 'color-mix(in srgb, currentColor 12%, transparent)';

List<StyleRule> get _styles => [
  css('.docs-sidebar', [
    css('&').styles(
      position: Position.relative(),
      padding: Padding.only(left: .5.rem, right: .75.rem, bottom: 3.rem, top: .75.rem),
      fontSize: .875.rem,
      lineHeight: 1.25.rem,
    ),
    css.media(MediaQuery.all(minWidth: 1024.px), [
      css('&').styles(padding: Padding.only(top: 1.rem)),
    ]),

    css('.sidebar-close', [
      css('&').styles(
        position: Position.absolute(top: .75.rem, right: .75.rem),
        border: Border.unset,
        cursor: Cursor.pointer,
        color: Color('inherit'),
        backgroundColor: Colors.transparent,
      ),
      css.media(MediaQuery.all(minWidth: 1024.px), [css('&').styles(display: Display.none)]),
    ]),

    // The section name is only worth the vertical space where the header's
    // tabs are hidden.
    css('.docs-sidebar-section', [
      css('&').styles(
        display: Display.flex,
        padding: Padding.only(left: .75.rem, bottom: .75.rem),
        margin: Margin.only(bottom: .5.rem),
        border: Border.only(
          bottom: BorderSide(width: 1.px, color: Color(_hairline)),
        ),
        alignItems: AlignItems.center,
        gap: Gap.column(.5.rem),
        color: ContentColors.primary,
        fontSize: .8125.rem,
        fontWeight: FontWeight.w700,
        textTransform: TextTransform.upperCase,
        letterSpacing: .04.em,
      ),
      css('.docs-sidebar-section-icon').styles(display: Display.flex),
      css.media(MediaQuery.all(minWidth: 1024.px), [css('&').styles(display: Display.none)]),
    ]),

    css('ul').styles(padding: Padding.zero, margin: Margin.zero, listStyle: ListStyle.none),

    css('.docs-sidebar-link', [
      css('&').styles(
        display: Display.flex,
        padding: Padding.symmetric(horizontal: .75.rem, vertical: .375.rem),
        margin: Margin.only(bottom: 1.px),
        radius: BorderRadius.circular(.375.rem),
        opacity: .75,
        transition: Transition('all', duration: 150.ms, curve: Curve.easeInOut),
        alignItems: AlignItems.center,
        gap: Gap.column(.5.rem),
        color: Color('inherit'),
        textDecoration: TextDecoration.none,
      ),
      css('&:hover').styles(
        opacity: 1,
        backgroundColor: Color('color-mix(in srgb, currentColor 6%, transparent)'),
      ),
      css('&.active').styles(
        opacity: 1,
        color: ContentColors.primary,
        fontWeight: FontWeight.w600,
        backgroundColor: Color('color-mix(in srgb, currentColor 14%, transparent)'),
      ),
      css('span:first-child').styles(
        overflow: Overflow.hidden,
        textOverflow: TextOverflow.ellipsis,
        whiteSpace: WhiteSpace.noWrap,
      ),
    ]),

    css('.docs-sidebar-badge').styles(
      padding: Padding.symmetric(horizontal: .3125.rem),
      radius: BorderRadius.circular(999.px),
      flex: Flex(shrink: 0),
      color: ContentColors.primary,
      fontSize: .625.rem,
      fontWeight: FontWeight.w700,
      textTransform: TextTransform.upperCase,
      letterSpacing: .03.em,
      backgroundColor: Color('color-mix(in srgb, currentColor 15%, transparent)'),
    ),

    css('.docs-sidebar-group-item').styles(listStyle: ListStyle.none),

    css('.docs-sidebar-group', [
      css('& > ul').styles(
        padding: Padding.only(left: .5.rem),
        margin: Margin.only(bottom: .5.rem, left: 1.0625.rem),
        border: Border.only(
          left: BorderSide(width: 1.px, color: Color(_hairline)),
        ),
      ),
      css(
        '&[open] > .docs-sidebar-summary .docs-sidebar-chevron svg',
      ).styles(transform: Transform.rotate(90.deg)),
      // A nested group sits inside a parent's indent already, so it drops the
      // icon slot and reads a size smaller than its parent heading.
      css(
        '&.nested > .docs-sidebar-summary',
      ).styles(opacity: .85, fontSize: .8125.rem, fontWeight: FontWeight.w600),
      css('&.nested > ul').styles(
        margin: Margin.only(bottom: .25.rem, left: .5.rem),
      ),
    ]),

    css('.docs-sidebar-summary', [
      css('&').styles(
        display: Display.flex,
        padding: Padding.symmetric(horizontal: .5.rem, vertical: .4375.rem),
        radius: BorderRadius.circular(.375.rem),
        cursor: Cursor.pointer,
        userSelect: UserSelect.none,
        alignItems: AlignItems.center,
        gap: Gap.column(.5.rem),
        listStyle: ListStyle.none,
        fontWeight: FontWeight.w600,
      ),
      css('&::-webkit-details-marker').styles(display: Display.none),
      css(
        '&:hover',
      ).styles(backgroundColor: Color('color-mix(in srgb, currentColor 6%, transparent)')),
      css('.docs-sidebar-icon').styles(display: Display.flex, opacity: .6, flex: Flex(shrink: 0)),
      css('.docs-sidebar-title').styles(flex: Flex(grow: 1)),
      css('.docs-sidebar-chevron', [
        css('&').styles(display: Display.flex, opacity: .45),
        css('svg').styles(
          transition: Transition('transform', duration: 150.ms, curve: Curve.easeInOut),
        ),
      ]),
    ]),
  ]),
];
