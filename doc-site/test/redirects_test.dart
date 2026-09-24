/// Keeps `lib/src/redirects.dart` honest.
///
/// A redirect is only useful while its source is gone and its target is not,
/// and a stale entry fails silently in both directions: a key that is a live
/// page gets shadowed, and a target that moved sends readers to a 404.
library;

import 'dart:io';

import 'package:revali_docs/src/redirects.dart';
import 'package:test/test.dart';

import 'support/docs_root.dart';

void main() {
  final root = docsRoot();

  bool isPage(String route) =>
      File('$root/content$route.md').existsSync() ||
      File('$root/content$route/index.md').existsSync();

  test('no redirect shadows a live page', () {
    final live = [
      for (final from in redirects.keys)
        if (isPage(from)) from,
    ];
    expect(live, isEmpty, reason: 'remove these from lib/src/redirects.dart');
  });

  test('every redirect targets a live page', () {
    final dead = [
      for (final MapEntry(key: from, value: to) in redirects.entries)
        if (!isPage(to.split('#').first)) '$from -> $to',
    ];
    expect(dead, isEmpty);
  });

  final buildDir = Directory('$root/build/jaspr');

  test('every stub is built, and every target anchor exists', () {
    final problems = <String>[];
    for (final MapEntry(key: from, value: to) in redirects.entries) {
      final stub = File('${buildDir.path}$from/index.html');
      if (!stub.existsSync() || !stub.readAsStringSync().contains('http-equiv="refresh"')) {
        problems.add('$from: no stub (run tool/build_redirects.dart after the build)');
      }

      final [route, ...fragment] = to.split('#');
      if (fragment.isEmpty) continue;
      final page = File('${buildDir.path}$route/index.html');
      if (!page.existsSync() || !page.readAsStringSync().contains('id="${fragment.single}"')) {
        problems.add('$from -> $to: no such anchor in the built page');
      }
    }
    expect(problems, isEmpty);
  }, skip: buildDir.existsSync() ? null : 'run `jaspr build` first');
}
