/// Checks that `sitemap.xml` and every page's own `rel=canonical` agree.
///
/// This is the assertion that would have caught the defect these files exist to
/// fix. The sitemap listed `/revali/cli/dev` and the page declared
/// `/revali/cli/dev` as canonical, so the two agreed perfectly — with each
/// other, and with neither the URL GitHub Pages serves. Checking either one in
/// isolation passes. Checking them *against the rendered HTML* is what fails.
///
/// Requires a build: run `jaspr build` then `dart run tool/build_sitemap.dart`
/// before `dart test`, the same way `search_index_test.dart`'s anchor test
/// needs one.
library;

import 'dart:io';

import 'package:test/test.dart';

import 'support/docs_root.dart';

/// Pulls the href out of `<link href="..." rel="canonical"/>`.
///
/// Deliberately tolerant of attribute order, since jaspr chooses it and a
/// reordering upstream would otherwise read as "no page has a canonical tag" --
/// which this file would then report as 111 failures rather than passing on
/// zero comparisons.
final _canonical = RegExp(
  r'<link[^>]*\brel="canonical"[^>]*>|<link[^>]*\bhref="([^"]*)"[^>]*\brel="canonical"',
);
final _href = RegExp(r'href="([^"]*)"');
final _loc = RegExp(r'<loc>([^<]*)</loc>');

void main() {
  final root = docsRoot();
  final build = Directory('$root/build/jaspr');
  final sitemapFile = File('${build.path}/sitemap.xml');

  // A guard, not a skip: if the build is missing, every assertion below would
  // vacuously pass on an empty list.
  test('the build and its sitemap exist', () {
    expect(
      build.existsSync(),
      isTrue,
      reason: 'run `dart run jaspr_cli:jaspr build` before `dart test`',
    );
    expect(
      sitemapFile.existsSync(),
      isTrue,
      reason: 'run `dart run tool/build_sitemap.dart` after the build',
    );
  }, skip: _skipReason(build, sitemapFile));

  group('sitemap', () {
    final locs = sitemapFile.existsSync()
        ? _loc.allMatches(sitemapFile.readAsStringSync()).map((m) => m.group(1)!).toList()
        : <String>[];

    test('lists every page, and nothing that is not one', () {
      expect(locs, isNotEmpty);
      // One <loc> per rendered page. `packages/` is build_web_compilers output
      // that the deploy prunes, so it is not a page and must not be listed.
      final rendered = build
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('index.html'))
          .where((f) => !f.path.contains('/packages/'))
          .length;
      expect(locs.length, rendered);
    }, skip: _skipReason(build, sitemapFile));

    test(
      'every URL ends in a slash, which is what GitHub Pages serves',
      () {
        expect(locs.where((loc) => !loc.endsWith('/')), isEmpty);
      },
      skip: _skipReason(build, sitemapFile),
    );

    test('every URL matches that page rel=canonical byte for byte', () {
      final mismatches = <String>[];

      for (final loc in locs) {
        final path = Uri.parse(loc).path;
        final file = File(
          '${build.path}$path/index.html'.replaceAll('//index.html', '/index.html'),
        );
        if (!file.existsSync()) {
          mismatches.add('$loc -> no page at ${file.path}');
          continue;
        }
        final html = file.readAsStringSync();
        final match = _canonical.firstMatch(html);
        // Reported as "(none)", never skipped: if the markup changes shape and
        // the regex stops matching, all 111 fail at once instead of this test
        // quietly comparing nothing.
        final canonical = match == null
            ? '(none)'
            : (match.group(1) ?? _href.firstMatch(match.group(0)!)?.group(1) ?? '(none)');
        if (canonical != loc) mismatches.add('$loc -> canonical $canonical');
      }

      expect(
        mismatches,
        isEmpty,
        reason:
            'sitemap and rel=canonical disagree; both come from canonicalUrl, so one caller drifted',
      );
    }, skip: _skipReason(build, sitemapFile));
  });
}

/// `null` when the build is present, or a reason string when it is not.
///
/// The tests are skipped rather than failed on a fresh checkout, because
/// `dart test` legitimately runs before a build locally. CI always builds
/// first, so nothing is skipped there.
String? _skipReason(Directory build, File sitemap) {
  if (!build.existsSync()) return 'no build/jaspr -- run `jaspr build` first';
  if (!sitemap.existsSync()) return 'no sitemap.xml -- run `tool/build_sitemap.dart`';
  return null;
}
