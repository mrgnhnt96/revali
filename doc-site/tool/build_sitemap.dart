/// Writes `build/jaspr/sitemap.xml`.
///
/// Replaces `jaspr build --sitemap-domain`, which cannot be used here. That
/// flag emits `<loc>$domain$route` with no hook to shape the URL, and this site
/// is served by GitHub Pages, which 301-redirects the no-slash form of every
/// route. So the flag produced a sitemap of 111 redirects that agreed exactly
/// with a `rel=canonical` naming the same redirecting URL — see
/// `lib/src/canonical.dart` for why that is the bad kind of wrong.
///
/// Owning the file is what lets [canonicalUrl] serve both the sitemap and the
/// canonical tag, so the two cannot drift into advertising different URLs.
///
/// Run AFTER `jaspr build`: `jaspr build` deletes `build/jaspr/` on the way in,
/// so a sitemap written before it is thrown away. It is generated rather than
/// committed to `web/` so the `lastmod` dates stay true — committing a
/// generated file changes the date it claims about itself.
///
/// Pass `--check` to verify without writing. Non-zero exit means the sitemap
/// that would be generated differs from the one on disk.
library;

import 'dart:io';

import 'package:revali_docs/src/canonical.dart';
import 'package:revali_docs/src/git_lastmod.dart';
import 'package:yaml/yaml.dart' as yaml;

Future<void> main(List<String> args) async {
  final check = args.contains('--check');

  final root = _docsRoot();
  final contentDir = Directory('${root.path}/content');
  if (!contentDir.existsSync()) {
    stderr.writeln('No content directory at ${contentDir.path}');
    exitCode = 1;
    return;
  }

  final origin = _siteUrl(root);
  if (origin == null) {
    stderr.writeln('content/_data/site.yaml has no `url:` — cannot build absolute URLs.');
    exitCode = 1;
    return;
  }

  final pages = contentDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.md'))
      .toList();

  if (pages.isEmpty) {
    stderr.writeln('No markdown pages under ${contentDir.path}.');
    exitCode = 1;
    return;
  }

  // Dates are keyed the way git prints them, relative to the project root.
  final dates = gitDates();
  if (dates.isEmpty) {
    stderr.writeln(
      'WARNING: git returned no dates for content/. Every page will be stamped '
      'with the build time, which is the signal-free sitemap this tool exists '
      'to avoid. A shallow clone is the usual cause — CI needs fetch-depth: 0.',
    );
  }

  final now = DateTime.now().toUtc().toIso8601String();
  final entries = <_Entry>[];

  for (final page in pages) {
    final route = _routeFor(page.path, contentDir.path);
    final relative = 'content${page.path.substring(contentDir.path.length).replaceAll(r'\', '/')}';
    entries.add(
      _Entry(
        loc: canonicalUrl(origin, route),
        // An undated page is one git has never seen -- newly written, and it
        // really did change just now.
        lastmod: dates[relative] ?? now,
      ),
    );
  }

  // Sorted so the file is stable across runs: `listSync` order is filesystem
  // order, which differs between machines, and an unstable file makes --check
  // fail for no reason.
  entries.sort((a, b) => a.loc.compareTo(b.loc));

  final sitemap = _render(entries);
  final target = File('${root.path}/build/jaspr/sitemap.xml');

  if (check) {
    if (!target.existsSync()) {
      stderr.writeln('${target.path} does not exist. Run `jaspr build`, then this tool.');
      exitCode = 1;
      return;
    }
    if (target.readAsStringSync() != sitemap) {
      stderr.writeln('${target.path} is stale. Re-run `dart run tool/build_sitemap.dart`.');
      exitCode = 1;
      return;
    }
    stdout.writeln('sitemap.xml is current (${entries.length} URLs).');
    return;
  }

  if (!target.parent.existsSync()) {
    stderr.writeln(
      'No ${target.parent.path}. Run `jaspr build` first -- it deletes that '
      'directory on the way in, so the sitemap has to be written after it.',
    );
    exitCode = 1;
    return;
  }

  target.writeAsStringSync(sitemap);
  stdout.writeln('Wrote ${target.path} (${entries.length} URLs).');
}

String _render(List<_Entry> entries) {
  final buffer = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">');

  for (final entry in entries) {
    buffer
      ..writeln('  <url>')
      ..writeln('    <loc>${entry.loc}</loc>')
      ..writeln('    <lastmod>${entry.lastmod}</lastmod>')
      // No changefreq or priority: Google ignores both outright, and a field
      // nobody reads is a field that can rot without anyone noticing.
      ..writeln('  </url>');
  }

  buffer.writeln('</urlset>');
  return buffer.toString();
}

/// `content/revali/cli/dev.md` -> `/revali/cli/dev`, `index.md` -> its
/// directory.
///
/// Mirrors `jaspr_content`'s own url derivation, which drops a trailing `index`
/// segment. `test/navigation_test.dart` already checks the two agree by
/// resolving every route back to a file.
String _routeFor(String path, String contentPath) {
  var relative = path.substring(contentPath.length).replaceAll(r'\', '/');
  relative = relative.replaceFirst(RegExp('^/'), '').replaceFirst(RegExp(r'\.md$'), '');
  if (relative == 'index') return '/';
  if (relative.endsWith('/index')) {
    relative = relative.substring(0, relative.length - '/index'.length);
  }
  return '/$relative';
}

String? _siteUrl(Directory root) {
  final file = File('${root.path}/content/_data/site.yaml');
  if (!file.existsSync()) return null;
  final data = yaml.loadYaml(file.readAsStringSync());
  if (data is! yaml.YamlMap) return null;
  final url = data['url'];
  return url is String && url.isNotEmpty ? url : null;
}

/// Locates `doc-site/` from wherever this was invoked.
Directory _docsRoot() {
  var directory = Directory.current;
  for (var i = 0; i < 4; i++) {
    if (File('${directory.path}/content/index.md').existsSync()) return directory;
    final nested = Directory('${directory.path}/doc-site');
    if (File('${nested.path}/content/index.md').existsSync()) return nested;
    directory = directory.parent;
  }
  throw StateError('Could not find doc-site/content from ${Directory.current.path}');
}

class _Entry {
  const _Entry({required this.loc, required this.lastmod});

  final String loc;
  final String lastmod;
}
