/// The entrypoint for the **server** environment.
///
/// This site is `mode: static`, so "server" here means build time: this runs
/// once per page during `jaspr build` and its output is the shipped HTML.
/// There is no `main.client.dart` and no `@client` component anywhere — the
/// interaction layer is `web/motion.js` and `web/analytics.js`, plain
/// JavaScript that costs far less than a dart2js bundle doing the same job.
library;

import 'dart:async';
import 'dart:convert';

import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';

import 'sections/chrome.dart';
import 'sections/features.dart';
import 'sections/hero.dart';
import 'sections/lifecycle.dart';
import 'sections/loop.dart';
import 'sections/not_found.dart';
import 'sections/pipeline.dart';
import 'sections/privacy.dart';
import 'sections/quickstart.dart';

const _url = 'https://revali.dev';

/// Versioned, and not `images/og.png`: `doc-site/tool/gen_logo_assets.sh` syncs
/// that name from the docs site. Rendered from `tool/og_home.html`.
const _image = '$_url/images/og-home-2026-11.png';

const _privacyPath = '/privacy/';

/// A root-level file because that is the name GitHub Pages serves for a miss.
const _notFoundPath = '/404.html';

/// What differs from one page to the next. The shell around it is shared.
class _Page {
  const _Page({required this.title, required this.description, required this.body, this.path});

  final String title;
  final String description;
  final List<Component> body;

  /// The public path. Null for a page that must not be indexed.
  final String? path;

  String? get url => switch (path) {
    null => null,
    '/' => _url,
    final path => '$_url$path',
  };
}

const _home = _Page(
  title: 'Revali: a Dart backend framework that generates your server',
  description:
      'Revali is a Dart backend framework. It reads the annotations on your '
      'classes and generates the server. Add constructs for a type-safe '
      'client, an OpenAPI document and a Dockerfile.',
  path: '/',
  body: [Hero(), Pipeline(), Lifecycle(), Features(), Loop(), Quickstart()],
);

const _privacy = _Page(
  title: 'Privacy | Revali',
  description:
      'What revali.dev records with PostHog and Amplitude, the cookies they '
      'set, how long the data is kept and how to turn analytics off.',
  path: _privacyPath,
  body: [Privacy()],
);

const _notFound = _Page(
  title: 'Page not found | Revali',
  description: 'This page does not exist on revali.dev.',
  body: [NotFound()],
);

_Page _pageAt(String url) {
  final path = '/${Uri.parse(url).path.replaceFirst(RegExp('^/+'), '')}';
  if (path.startsWith('/privacy')) return _privacy;
  if (path == _notFoundPath) return _notFound;
  return _home;
}

void main() {
  Jaspr.initializeApp();
  runApp(const _Site());
}

class _Site extends AsyncStatelessComponent {
  const _Site();

  @override
  Future<Component> build(BuildContext context) async {
    // Jaspr only renders `/` on its own. Both calls do nothing outside a build.
    // Awaited because the build stops once `/` responds with nothing queued,
    // so a request that arrives late silently drops that page.
    await ServerApp.requestRouteGeneration(_privacyPath);
    await ServerApp.requestRouteGeneration(_notFoundPath);

    final page = _pageAt(context.url);
    final url = page.url;

    if (url == null) context.setHeader('jaspr-sitemap-data', 'false');

    return Document(
      title: page.title,
      lang: 'en',
      viewport: 'width=device-width, initial-scale=1',
      // Everything in this map renders as `name=`, which is why no `og:` tag is
      // in it — see the block in `head:` below.
      meta: {
        'description': page.description,
        'theme-color': '#07080c',
        if (url == null) 'robots': 'noindex',
        // `twitter:*` genuinely is a `name=` vocabulary, per X's card spec, so
        // these belong here and not with the og tags.
        if (url != null) ...{
          'twitter:card': 'summary_large_image',
          'twitter:title': page.title,
          'twitter:description': page.description,
          'twitter:image': _image,
        },
      },
      head: [
        // Open Graph is RDFa, so it is only valid — and only parsed — as
        // `property="og:…"`. Jaspr's `meta:` map cannot express that: it builds
        // every entry as `{'name': key, 'content': value}` and the attribute
        // name is not a function of the key, so an `og:` entry in the map above
        // emits `name="og:image"`, which a parser normalising on `property`
        // reads as no og:image at all. That is what dropped the image from the
        // X link card and demoted it to the small `summary` layout. Do not
        // "tidy" these back into the map. `doc-site/lib/main.server.dart` emits
        // its per-page og tags the same way for the same reason.
        if (url != null) ...[
          meta(attributes: {'property': 'og:type'}, content: 'website'),
          meta(attributes: {'property': 'og:site_name'}, content: 'Revali'),
          meta(attributes: {'property': 'og:title'}, content: page.title),
          meta(attributes: {'property': 'og:description'}, content: page.description),
          meta(attributes: {'property': 'og:url'}, content: url),
          meta(attributes: {'property': 'og:image'}, content: _image),
          meta(attributes: {'property': 'og:image:width'}, content: '1200'),
          meta(attributes: {'property': 'og:image:height'}, content: '630'),
          link(rel: 'canonical', href: url),
        ],
        link(rel: 'icon', href: '/favicon.png', attributes: {'type': 'image/png'}),
        link(rel: 'stylesheet', href: '/styles.css'),
        // `defer` rather than `async`: motion.js reads the DOM immediately on
        // execution, and defer is the one that guarantees the document is
        // parsed first while still not blocking rendering.
        script(src: '/motion.js', defer: true),
        script(src: '/analytics.js', defer: true),
        // Gives the rich result a name and description of its own rather than
        // letting a crawler infer them from the <title>.
        if (identical(page, _home))
          script(attributes: {'type': 'application/ld+json'}, content: _structuredData),
      ],
      body: _Body(page.body),
    );
  }
}

class _Body extends StatelessComponent {
  const _Body(this.sections);

  final List<Component> sections;

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      const Ambient(),
      div(classes: 'page', [const SiteHeader(), main_(sections), const SiteFooter()]),
    ]);
  }
}

final _structuredData = jsonEncode({
  '@context': 'https://schema.org',
  '@graph': [
    {
      '@type': 'SoftwareApplication',
      'name': 'Revali',
      'applicationCategory': 'DeveloperApplication',
      'operatingSystem': 'Any',
      'description': _home.description,
      'url': _url,
      'license': 'https://opensource.org/licenses/MIT',
      'offers': {'@type': 'Offer', 'price': '0', 'priceCurrency': 'USD'},
    },
    {'@type': 'WebSite', 'name': 'Revali', 'url': _url},
    {
      '@type': 'Organization',
      'name': 'MRGNHNT, LLC',
      'url': _url,
      'logo': '$_url/favicon.png',
      'sameAs': ['https://github.com/mrgnhnt96/revali'],
    },
  ],
});
