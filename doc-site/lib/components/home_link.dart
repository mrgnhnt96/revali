/// The header's link back to the marketing site at revali.dev.
///
/// The docs and the landing page are two hosts, and until this existed the
/// relationship between them ran one way: revali.dev links here four times,
/// docs.revali.dev linked back only to GitHub. A crawler had nothing tying the
/// two together as one project, and a reader who arrived on a deep link from a
/// search result had no route to the overview at all.
///
/// A plain link, deliberately: it renders into the static HTML of all 111
/// pages, which is the whole point — a script-built one would be invisible to
/// the crawler it is here for.
library;

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Links to <https://revali.dev>.
class HomeLink extends StatelessComponent {
  const HomeLink({super.key});

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      Document.head(children: [Style(styles: _styles)]),
      a(
        href: 'https://revali.dev',
        classes: 'home-link',
        // No `target: blank`. This is the same project on a sibling host, not
        // an outbound reference, and a reader following it is going *back* to
        // the overview -- a new tab for that leaves them with two.
        attributes: {'title': 'The Revali home page'},
        [Component.text('revali.dev')],
      ),
    ]);
  }
}

List<StyleRule> get _styles => [
  css('.home-link', [
    css('&').styles(
      // Hidden on narrow screens for the same reason `.section-tabs` is: the
      // header runs out of room beside the logo and the search box. It stays in
      // the markup either way, so the link is still there to be followed.
      display: Display.none,
      padding: Padding.symmetric(horizontal: .7.rem, vertical: .4.rem),
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
    css.media(MediaQuery.all(minWidth: 1024.px), [css('&').styles(display: Display.flex)]),
    css('&:hover').styles(
      opacity: 1,
      backgroundColor: Color('color-mix(in srgb, currentColor 6%, transparent)'),
    ),
  ]),
];
