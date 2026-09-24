/// Writes a redirect stub for every route in `lib/src/redirects.dart`.
///
/// Run AFTER `jaspr build`, which deletes `build/jaspr/` on the way in:
///
/// ```sh
/// dart run jaspr_cli:jaspr build && dart run tool/build_redirects.dart
/// ```
///
/// GitHub Pages has no server-side redirects, so each stub is a tiny page with
/// a meta refresh, a `rel=canonical` naming the target (so search engines move
/// the old URL's standing over rather than indexing a duplicate), `noindex`,
/// and a plain link for anything that ignores the refresh.
library;

import 'dart:io';

import 'package:revali_docs/src/canonical.dart';
import 'package:revali_docs/src/redirects.dart';
import 'package:yaml/yaml.dart' as yaml;

void main() {
  final root = _docsRoot();
  final build = Directory('${root.path}/build/jaspr');
  if (!build.existsSync()) {
    stderr.writeln('No build at ${build.path}. Run `dart run jaspr_cli:jaspr build` first.');
    exitCode = 1;
    return;
  }

  final origin = _siteUrl(root);
  if (origin == null) {
    stderr.writeln('content/_data/site.yaml has no `url:` — cannot build absolute URLs.');
    exitCode = 1;
    return;
  }

  for (final MapEntry(key: from, value: to) in redirects.entries) {
    final file = File('${build.path}$from/index.html');
    // A stub must never replace a real page: that is a page silently deleted.
    // An earlier stub is fine to overwrite, so the tool can be re-run.
    if (file.existsSync() && !file.readAsStringSync().contains('http-equiv="refresh"')) {
      stderr.writeln('$from is a live page; remove it from lib/src/redirects.dart.');
      exitCode = 1;
      return;
    }

    final (route, fragment) = switch (to.split('#')) {
      [final route, final fragment] => (route, '#$fragment'),
      _ => (to, ''),
    };
    final canonical = canonicalUrl(origin, route);

    file
      ..createSync(recursive: true)
      ..writeAsStringSync(_stub(canonical: canonical, target: '$canonical$fragment'));
  }

  stdout.writeln('Wrote ${redirects.length} redirects into ${build.path}.');
}

String _stub({required String canonical, required String target}) =>
    '''
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Moved</title>
<meta name="robots" content="noindex">
<link rel="canonical" href="$canonical">
<meta http-equiv="refresh" content="0; url=$target">
</head>
<body>
<p>This page has moved to <a href="$target">$target</a>.</p>
</body>
</html>
''';

String? _siteUrl(Directory root) {
  final file = File('${root.path}/content/_data/site.yaml');
  if (!file.existsSync()) return null;
  final data = yaml.loadYaml(file.readAsStringSync());
  if (data is! yaml.YamlMap) return null;
  final url = data['url'];
  return url is String && url.isNotEmpty ? url : null;
}

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
