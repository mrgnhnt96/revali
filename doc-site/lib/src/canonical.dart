/// The one place a route becomes a URL.
///
/// GitHub Pages serves `foo/index.html` at `/foo/` and **301-redirects** `/foo`
/// to it. Every page on this site is an `index.html`, so the URL a reader
/// actually lands on always ends in a slash, while `page.url` and the sidebar
/// hrefs never do. Anything that publishes an absolute URL — `rel=canonical`,
/// `og:url`, `sitemap.xml` — has to bridge that gap or it advertises a
/// redirect.
///
/// This existed as three independent `'$base${page.url}'` concatenations
/// before, and all three were wrong in the same way: the canonical tag named a
/// URL the page is not served at, and the sitemap agreed with the tag. Two
/// wrongs that match produce no symptom at all — nothing 404s, nothing
/// contradicts anything, and the only place it surfaces is a Search Console
/// report about duplicate URLs months later.
///
/// So the conversion lives here, once, and [canonicalUrl] is the only way to
/// build one. [assetUrl] is its counterpart for the case that must NOT get a
/// slash — naming both is the point, since conflating them is the bug.
library;

/// The absolute, canonical URL of the page at [route] on [origin].
///
/// [origin] is the site root (`https://docs.revali.dev`), [route] a
/// root-absolute path as `page.url` gives it (`/revali/cli/dev`, or `/` for the
/// home page). The result always ends in `/`, which is the form GitHub Pages
/// serves with a 200.
String canonicalUrl(String origin, String route) {
  final base = _trimTrailingSlashes(origin);
  final path = _trimTrailingSlashes(route);

  // The root is just the origin plus the slash every other route also ends in;
  // '' would produce a bare `https://host` with no path at all.
  if (path.isEmpty || path == '/') return '$base/';

  final leading = path.startsWith('/') ? '' : '/';
  return '$base$leading$path/';
}

/// The absolute URL of a static file at [path] on [origin].
///
/// Files are served at exactly their path, so unlike [canonicalUrl] this must
/// not add a trailing slash — `/images/og/x.png/` is a 404. Used for `og:image`
/// and `twitter:image`, which scrapers fetch out of context and so cannot be
/// root-relative.
String assetUrl(String origin, String path) {
  final base = _trimTrailingSlashes(origin);
  final leading = path.startsWith('/') ? '' : '/';
  return '$base$leading$path';
}

/// Drops trailing slashes so callers can pass either form without doubling up.
String _trimTrailingSlashes(String value) {
  var end = value.length;
  while (end > 0 && value[end - 1] == '/') {
    end--;
  }
  return value.substring(0, end);
}
