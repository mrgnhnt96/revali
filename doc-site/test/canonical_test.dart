/// Checks the route -> URL conversion every published URL goes through.
///
/// The bug this replaced was not a crash: `'$base${page.url}'` produced a
/// perfectly well-formed URL that GitHub Pages happened to 301 away from. So
/// the assertions here are about the trailing slash specifically, since that is
/// the entire difference between a canonical URL and a redirect.
library;

import 'package:revali_docs/src/canonical.dart';
import 'package:test/test.dart';

const origin = 'https://docs.revali.dev';

void main() {
  group('canonicalUrl', () {
    test('ends a page URL with a slash, which is what Pages serves', () {
      expect(canonicalUrl(origin, '/revali/cli/dev'), 'https://docs.revali.dev/revali/cli/dev/');
    });

    test('maps the root route to the bare origin plus a slash', () {
      expect(canonicalUrl(origin, '/'), 'https://docs.revali.dev/');
    });

    test('does not double the slash when the route already has one', () {
      expect(canonicalUrl(origin, '/revali/cli/dev/'), 'https://docs.revali.dev/revali/cli/dev/');
    });

    test('tolerates an origin written with a trailing slash', () {
      // site.yaml is hand-edited, and `url: https://docs.revali.dev/` is an
      // entirely reasonable thing to write there.
      expect(
        canonicalUrl('$origin/', '/revali/messaging'),
        'https://docs.revali.dev/revali/messaging/',
      );
    });

    test('is idempotent, so a URL can be re-canonicalised safely', () {
      final once = canonicalUrl(origin, '/constructs/revali_client');
      expect(canonicalUrl(origin, once.substring(origin.length)), once);
    });

    test('never emits a bare origin with no path', () {
      // `https://host` with no trailing slash is a different URL to Google than
      // `https://host/`, and only the latter is what Pages serves.
      for (final route in ['/', '', '//']) {
        expect(canonicalUrl(origin, route), endsWith('/'));
        expect(canonicalUrl(origin, route), 'https://docs.revali.dev/');
      }
    });
  });

  group('assetUrl', () {
    test('does NOT add a trailing slash, which would 404 the file', () {
      expect(
        assetUrl(origin, '/images/og/revali-cli-dev.png'),
        'https://docs.revali.dev/images/og/revali-cli-dev.png',
      );
    });

    test('differs from canonicalUrl for the same path', () {
      // The whole reason both exist. If these ever agree, one of them is wrong.
      const path = '/images/og/index.png';
      expect(assetUrl(origin, path), isNot(canonicalUrl(origin, path)));
    });
  });
}
