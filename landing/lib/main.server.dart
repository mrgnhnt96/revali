/// The entrypoint for the **server** environment.
///
/// This site is `mode: static`, so "server" here means build time: this runs
/// once per page during `jaspr build` and its output is the shipped HTML.
/// There is no `main.client.dart` and no `@client` component anywhere — the
/// interaction layer is `web/motion.js`, ~4KB of plain JavaScript, which is
/// far less than a dart2js bundle would cost to do the same four things.
library;

import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';

import 'sections/chrome.dart';
import 'sections/features.dart';
import 'sections/hero.dart';
import 'sections/lifecycle.dart';
import 'sections/loop.dart';
import 'sections/pipeline.dart';
import 'sections/quickstart.dart';

const _title = 'Revali — Build powerful APIs with Dart';
const _description =
    'Revali reads the annotations on your Dart classes and generates the '
    'server, a type-safe client, an OpenAPI document and a Dockerfile. One '
    'command, no boilerplate, hot reload included.';
const _url = 'https://revali.dev';
const _image = '$_url/images/og.png';

void main() {
  Jaspr.initializeApp();
  runApp(const _Site());
}

class _Site extends StatelessComponent {
  const _Site();

  @override
  Component build(BuildContext context) {
    return Document(
      title: _title,
      lang: 'en',
      viewport: 'width=device-width, initial-scale=1',
      // Everything in this map renders as `name=`, which is why no `og:` tag is
      // in it — see the block in `head:` below.
      meta: {
        'description': _description,
        'theme-color': '#07080c',
        // `twitter:*` genuinely is a `name=` vocabulary, per X's card spec, so
        // these belong here and not with the og tags.
        'twitter:card': 'summary_large_image',
        'twitter:title': _title,
        'twitter:description': _description,
        'twitter:image': _image,
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
        meta(attributes: {'property': 'og:type'}, content: 'website'),
        meta(attributes: {'property': 'og:site_name'}, content: 'Revali'),
        meta(attributes: {'property': 'og:title'}, content: _title),
        meta(attributes: {'property': 'og:description'}, content: _description),
        meta(attributes: {'property': 'og:url'}, content: _url),
        meta(attributes: {'property': 'og:image'}, content: _image),
        link(rel: 'icon', href: '/favicon.png', attributes: {'type': 'image/png'}),
        link(rel: 'canonical', href: _url),
        link(rel: 'stylesheet', href: '/styles.css'),
        // `defer` rather than `async`: motion.js reads the DOM immediately on
        // execution, and defer is the one that guarantees the document is
        // parsed first while still not blocking rendering.
        script(src: '/motion.js', defer: true),
        // Gives the rich result a name and description of its own rather than
        // letting a crawler infer them from the <title>.
        script(attributes: {'type': 'application/ld+json'}, content: _structuredData),
        script(content: _analytics),
      ],
      body: const _Body(),
    );
  }
}

class _Body extends StatelessComponent {
  const _Body();

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      const Ambient(),
      div(classes: 'page', [
        const SiteHeader(),
        main_([
          const Hero(),
          const Pipeline(),
          const Lifecycle(),
          const Features(),
          const Loop(),
          const Quickstart(),
        ]),
        const SiteFooter(),
      ]),
    ]);
  }
}

const _structuredData =
    '''
{
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  "name": "Revali",
  "applicationCategory": "DeveloperApplication",
  "operatingSystem": "Any",
  "description": "$_description",
  "url": "$_url",
  "license": "https://opensource.org/licenses/MIT",
  "offers": { "@type": "Offer", "price": "0", "priceCurrency": "USD" }
}
''';

/// The PostHog loader.
///
/// `content:` is emitted verbatim — `script(content:)` wraps the string in a
/// `RawText`, which renders unescaped — so this really is an inline `<script>`
/// body and not an escaped string sitting inertly in the DOM.
///
/// This is the readable loader rather than PostHog's minified snippet. The
/// minified one additionally stubs `posthog.*` into a queue, so calls made
/// before `array.js` lands are replayed once it does. Nothing on this site
/// calls PostHog outside this block — `web/motion.js` is the only other
/// JavaScript — so that queue would be dead weight here. If anything ever does
/// call `posthog.capture` directly, switch to the official snippet, which
/// handles exactly that case.
///
/// Loaded `async` and initialised from `onload`. Two plain tags would be
/// correctly ordered but render-blocking, and `defer` cannot buy that back:
/// `defer` is ignored on *inline* scripts, so the init would run before
/// `array.js` and throw.
///
/// The key is PostHog's public project key. The `phc_` prefix marks it
/// write-only and client-side; it is meant to ship in client HTML, so it is in
/// plain source deliberately — do not move it behind an env var or a
/// build-time substitution.
///
/// Raw string: JavaScript uses `$` freely and Dart would read it as
/// interpolation.
const _analytics = r'''
(function () {
  var s = document.createElement('script');
  s.src = 'https://us-assets.i.posthog.com/static/array.js';
  s.async = true;
  s.crossOrigin = 'anonymous';
  s.onload = function () {
    posthog.init('phc_JvQSPxWXO7nPNdqPEp1i1341AblCBRWZRpS0kKWRheu', {
      api_host: 'https://us.i.posthog.com',
      // Off deliberately: the free plan's 5k/month session-recording budget is
      // shared across every Revali site.
      disable_session_recording: true,
    });
  };
  document.head.appendChild(s);
})();
''';
