/// Per-page `<lastmod>` for `sitemap.xml`, taken from git history.
///
/// Without this, jaspr has no date to publish for a route and falls back to the
/// moment the build ran, so every URL in the sitemap claims to have changed on
/// every deploy. That is worse than useless: `lastmod` is the only one of the
/// three optional sitemap fields Google still reads — it ignores `changefreq`
/// and `priority` outright, which is why neither is set here — and it is
/// documented as being ignored on sites whose values are consistently
/// inaccurate. A sitemap that cries wolf 111 times per deploy earns exactly
/// that treatment, and then an edit to one page has no way to ask for a
/// re-crawl ahead of the 110 that did not change.
library;

import 'dart:convert';
import 'dart:io';

import 'package:jaspr/server.dart';
import 'package:jaspr_content/jaspr_content.dart';

/// The marker `--format` puts at the start of every date line.
///
/// A NUL is the one byte that cannot occur in a git path, so it is what tells a
/// date line from a path line. Naming it once keeps the `%x00` in the
/// `--format` argument and the check in [parseGitLog] from drifting apart —
/// they are two halves of one wire format, and nothing else would catch it.
const nulPrefix = '\u0000';

/// Stamps each page's `sitemap.lastmod` with the committer date of the last
/// commit that touched its markdown source.
///
/// Front matter wins: a page that sets its own `sitemap: {lastmod: ...}` is
/// left alone, and so is a page git has never heard of — a newly written file
/// really did change just now, and jaspr's build-time fallback is the right
/// answer for it.
class GitLastModDataLoader implements DataLoader {
  GitLastModDataLoader({this.directory = 'content'});

  /// The content directory, as passed to [FilesystemLoader].
  ///
  /// A [Page]'s `path` is relative to this directory, while git reports paths
  /// relative to the working directory, so this is the piece that joins the
  /// two. It is only correct because jaspr runs the build from the project
  /// root — the same assumption `FilesystemLoader('content')` already makes.
  final String directory;

  /// Path (as git prints it) -> committer date, read once for the whole build.
  ///
  /// `null` until the first page asks. One `git log` for 111 pages rather than
  /// 111 invocations of `git log -1 <file>`.
  Map<String, String>? _dates;

  @override
  Future<void> loadData(Page page) async {
    // Only the static build writes a sitemap, so `jaspr serve` should not pay
    // for a `git log` — and would otherwise serve a cached date that goes stale
    // the moment the page is edited, which is precisely what serve is for.
    if (!kGenerateMode) return;

    if (page.data.page['sitemap'] case final Map<Object?, Object?> sitemap
        when sitemap['lastmod'] != null) {
      return;
    }

    final lastmod = (_dates ??= _readDates())['$directory/${page.path}'];
    if (lastmod == null) return;

    // Merged, not assigned: a page may set `sitemap` in front matter for some
    // other key, and replacing the map wholesale would drop it.
    page.apply(
      data: {
        'page': {
          'sitemap': {'lastmod': lastmod},
        },
      },
    );
  }

  Map<String, String> _readDates() {
    final ProcessResult result;
    try {
      result = Process.runSync('git', [
        'log',
        // A NUL prefix is what separates a date line from a path line. Without
        // it the two are told apart by guessing at the shape of the text, and
        // a file named like a timestamp breaks the parse.
        '--format=%x00%cI',
        '--name-only',
        // Paths relative to the working directory, so they line up with
        // `$directory/${page.path}` no matter where the project sits in the
        // repository.
        '--relative',
        '--',
        directory,
      ]);
    } on ProcessException {
      // No git on PATH. Every page falls back to the build time, which is the
      // behaviour this class replaces — degraded, not broken.
      return const {};
    }
    if (result.exitCode != 0) return const {};
    return parseGitLog(result.stdout as String);
  }
}

/// Parses `git log --format=%x00%cI --name-only` output into path -> date.
///
/// Split out from [GitLastModDataLoader] because it is the part that can be
/// wrong in an interesting way, and a pure function over a string is testable
/// without a repository to point it at.
///
/// `git log` lists commits newest first, so the first date seen for a path is
/// its most recent one. Renames are not followed: after `git mv`, a page's
/// history restarts at the rename, which still dates it no earlier than the
/// commit that gave it its current URL.
Map<String, String> parseGitLog(String output) {
  final dates = <String, String>{};
  var date = '';

  for (final line in const LineSplitter().convert(output)) {
    if (line.startsWith(nulPrefix)) {
      date = line.substring(nulPrefix.length);
    } else if (line.isNotEmpty && date.isNotEmpty) {
      dates.putIfAbsent(line, () => date);
    }
  }

  return dates;
}
