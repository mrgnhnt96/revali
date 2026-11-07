import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

const _repoIssues = 'https://github.com/mrgnhnt96/revali/issues';
const _posthogPricing = 'https://posthog.com/pricing';
const _amplitudePricing = 'https://amplitude.com/pricing';
const _pagesData =
    'https://docs.github.com/en/pages/getting-started-with-github-pages/what-is-github-pages';

/// What each cookie is, measured from a real page load in Chrome on
/// 2026-11-06. If `web/analytics.js` changes, measure again and update this.
const _cookies = [
  ('ph_phc_…_posthog', 'PostHog', 'Random visitor and session IDs', '1 year'),
  ('AMP_15288b16e4', 'Amplitude', 'Random device and session IDs', '1 year'),
  ('AMP_MKTG_15288b16e4', 'Amplitude', 'The campaign and referrer you arrived from', '1 year'),
];

/// The privacy policy, which has to match what `web/analytics.js` loads.
class Privacy extends StatelessComponent {
  const Privacy();

  @override
  Component build(BuildContext context) {
    return section(classes: 'section prose', [
      div(classes: 'shell prose__inner', [
        h1(classes: 'section-title', [Component.text('Privacy')]),
        p(classes: 'prose__date', [Component.text('Last updated 6 November 2026')]),
        p([
          Component.text(
            'revali.dev is published by MRGNHNT, LLC, the copyright holder of '
            'Revali. This site has no accounts and no forms. It uses two '
            'analytics services to see which pages get read and which links '
            'get clicked. This page covers revali.dev only. The documentation '
            'at docs.revali.dev also uses PostHog and Amplitude.',
          ),
        ]),
        _control(),
        h2([Component.text('What runs')]),
        p([
          Component.text(
            'PostHog and Amplitude both load when a page opens, unless you have '
            'turned analytics off or your browser sends Global Privacy Control. '
            'Both send data to their servers in the United States. There is no '
            'consent banner. Session recording is off in both.',
          ),
        ]),
        h2([Component.text('What they record')]),
        ul([
          li([
            Component.text(
              'The pages you view, the page you came from, and any campaign or '
              'click ID in the link you followed.',
            ),
          ]),
          li([
            Component.text(
              'What you click: the element, its text and its position on the '
              'page. PostHog uses clicks to draw heatmaps.',
            ),
          ]),
          li([
            Component.text(
              'Page speed, failed requests, and signs of frustration such as '
              'repeated clicks. Amplitude records these.',
            ),
          ]),
          li([
            Component.text(
              'Your browser, operating system, device type, language, time '
              'zone, and screen and window size.',
            ),
          ]),
          li([Component.text('Random device and session IDs, kept in your browser.')]),
          li([
            Component.text(
              'Your IP address. Both services receive it with each request and '
              'may store it. Amplitude records it by default.',
            ),
          ]),
        ]),
        h2([Component.text('Cookies')]),
        p([
          Component.text(
            'These cookies last one year. Both services also keep the same kind '
            'of IDs in your browser\'s local and session storage.',
          ),
        ]),
        div(
          classes: 'prose__table',
          attributes: {'tabindex': '0', 'role': 'region', 'aria-label': 'Cookies'},
          [
            table([
              thead([
                tr([
                  th([Component.text('Cookie')]),
                  th([Component.text('Set by')]),
                  th([Component.text('Holds')]),
                  th([Component.text('Lasts')]),
                ]),
              ]),
              tbody([
                for (final (name, owner, holds, lasts) in _cookies)
                  tr([
                    td([
                      code([Component.text(name)]),
                    ]),
                    td([Component.text(owner)]),
                    td([Component.text(holds)]),
                    td([Component.text(lasts)]),
                  ]),
              ]),
            ]),
          ],
        ),
        h2([Component.text('How long data is kept')]),
        p([
          Component.text('Both services are on their free plans. '),
          a(href: _posthogPricing, [Component.text('PostHog\'s free plan')]),
          Component.text(' has one year of data retention. '),
          a(href: _amplitudePricing, [Component.text('Amplitude\'s free plan')]),
          Component.text(' gives access to one year of data.'),
        ]),
        h2([Component.text('Hosting')]),
        p([
          Component.text('This site is hosted on GitHub Pages. '),
          a(href: _pagesData, [Component.text('GitHub logs and stores')]),
          Component.text(
            ' the IP address of visitors to Pages sites for security, whether '
            'or not they are signed in to GitHub.',
          ),
        ]),
        h2([Component.text('Turning analytics off')]),
        p([
          Component.text(
            'Use the button at the top of this page. It stops both services in '
            'this browser and removes their cookies and stored IDs. It applies '
            'to revali.dev in this browser only, and data already collected stays '
            'with the services. Analytics need JavaScript, so with JavaScript '
            'off nothing is sent. If your browser sends Global Privacy Control, '
            'analytics never start.',
          ),
        ]),
        h2([Component.text('Questions')]),
        p([
          Component.text('Open an issue on '),
          a(href: _repoIssues, [Component.text('GitHub')]),
          Component.text(
            '. Issues are public, so leave personal details out and ask for a '
            'private way to continue.',
          ),
        ]),
      ]),
    ]);
  }

  Component _control() {
    return div(
      classes: 'optout',
      attributes: {'data-analytics': '', 'hidden': ''},
      [
        p(
          classes: 'optout__status',
          attributes: {'data-analytics-status': '', 'role': 'status'},
          [],
        ),
        button(
          classes: 'btn btn--ghost',
          attributes: {'type': 'button', 'data-analytics-toggle': ''},
          [Component.text('Turn analytics off')],
        ),
      ],
    );
  }
}
