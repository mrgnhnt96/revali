/// Locates the `doc-site` directory from wherever `dart test` was invoked.
library;

import 'dart:io';

/// The absolute path to `doc-site`.
///
/// `dart test` runs with the package root as the cwd, but CI and editors both
/// manage to invoke it from the repository root instead, and a test that only
/// works from one of those is a test that gets deleted.
String docsRoot() {
  var directory = Directory.current;
  for (var i = 0; i < 4; i++) {
    if (File('${directory.path}/content/index.md').existsSync()) return directory.path;
    final nested = Directory('${directory.path}/doc-site');
    if (File('${nested.path}/content/index.md').existsSync()) return nested.path;
    directory = directory.parent;
  }
  throw StateError('Could not find doc-site/content from ${Directory.current.path}');
}
