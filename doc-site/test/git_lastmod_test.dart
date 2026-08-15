/// Checks the parse that turns `git log` output into a per-page `<lastmod>`.
///
/// This is the part of `src/git_lastmod.dart` that can be wrong without
/// anything failing: a parse that drops every path publishes a sitemap of
/// build-time dates, which is exactly what the file exists to replace, and the
/// build still succeeds and the XML is still valid. Nothing downstream checks
/// that a date is *plausible*, so it gets checked here.
library;

import 'dart:io';

import 'package:revali_docs/src/git_lastmod.dart';
import 'package:test/test.dart';

/// A commit block as `--format=%x00%cI --name-only` emits it: the NUL-prefixed
/// date, a blank line, then one path per file the commit touched.
String commit(String date, List<String> paths) => '$nulPrefix$date\n\n${paths.join('\n')}\n';

void main() {
  group('parseGitLog', () {
    test('reads a date and the paths under it', () {
      final dates = parseGitLog(
        commit('2026-08-14T21:48:35-07:00', [
          'content/revali/index.md',
          'content/revali/cli/up.md',
        ]),
      );

      expect(dates, {
        'content/revali/index.md': '2026-08-14T21:48:35-07:00',
        'content/revali/cli/up.md': '2026-08-14T21:48:35-07:00',
      });
    });

    test('keeps the newest date when a page appears in several commits', () {
      // `git log` is newest-first, so the first date seen wins. Getting this
      // backwards would date every page by when it was *created*.
      final dates = parseGitLog(
        commit('2026-08-14T21:48:35-07:00', ['content/revali/messaging.md']) +
            commit('2026-08-01T08:00:00-07:00', ['content/revali/messaging.md']),
      );

      expect(dates['content/revali/messaging.md'], '2026-08-14T21:48:35-07:00');
    });

    test('emits dates DateTime can parse, since jaspr parses them', () {
      // jaspr_cli calls `DateTime.parse` on whatever lands in `lastmod`, so a
      // format it rejects is a failed deploy rather than a bad sitemap.
      final dates = parseGitLog(commit('2026-08-14T21:48:35-07:00', ['content/index.md']));

      expect(() => DateTime.parse(dates['content/index.md']!), returnsNormally);
    });

    test('ignores a path with no date ahead of it', () {
      expect(parseGitLog('content/orphan.md\n'), isEmpty);
    });

    test('is empty for empty output, rather than throwing', () {
      // What a repository with no commits touching content/ produces. The
      // caller treats an empty map as "fall back to build time".
      expect(parseGitLog(''), isEmpty);
    });

    test('does not mistake a path that looks like a date for one', () {
      // The reason the format carries a NUL at all: told apart by shape, a file
      // named like a timestamp would be read as a commit date and would take
      // the following paths with it.
      final dates = parseGitLog(
        commit('2026-08-14T21:48:35-07:00', ['content/2026-08-14T21:48:35-07:00.md']),
      );

      expect(dates, {'content/2026-08-14T21:48:35-07:00.md': '2026-08-14T21:48:35-07:00'});
    });
  });

  group('against this repository', () {
    // The unit tests above prove the parse; this proves the whole arrangement
    // -- the format string, the `--relative` paths and the key the loader
    // builds -- still agrees with the git that is actually installed. It is the
    // half that silently breaks if a flag is dropped, and it cannot be faked.
    test('dates real pages under content/', () {
      final result = Process.runSync('git', [
        'log',
        '--format=%x00%cI',
        '--name-only',
        '--relative',
        '--',
        'content',
      ]);

      // A CI checkout with `fetch-depth: 1` has one commit, so every page comes
      // back with the same date -- the failure this whole file guards against,
      // and it looks like success. Distinct dates is the evidence that history
      // is actually present.
      final dates = parseGitLog(result.stdout as String);

      expect(dates, isNotEmpty, reason: 'no history for content/ -- is this a shallow clone?');
      expect(
        dates.keys,
        contains('content/index.md'),
        reason: 'the paths git prints no longer match the keys the loader builds',
      );
      expect(
        dates.values.toSet().length,
        greaterThan(1),
        reason: 'every page shares one date -- a shallow clone, so lastmod would be meaningless',
      );
    });
  });
}
