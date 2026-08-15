/// Per-page `<lastmod>` for `sitemap.xml`, taken from git history.
///
/// Without a real date the sitemap has to claim every page changed at build
/// time, so all 111 URLs move on every deploy. `lastmod` is the only one of the
/// three optional sitemap fields Google still reads — it ignores `changefreq`
/// and `priority` outright, which is why neither is emitted — and it is
/// documented as being discounted on sites whose values are consistently
/// inaccurate. A sitemap that cries wolf 111 times per deploy earns exactly
/// that, and then a real edit has no way to ask for a re-crawl ahead of the 110
/// pages that did not change.
///
/// **This needs full git history.** A CI checkout defaults to a depth-1 clone,
/// where every path resolves to the single fetched commit — so the dates
/// collapse to one value and the sitemap looks perfectly well-formed while
/// carrying no information. `.github/workflows/deploy-docs.yml` sets
/// `fetch-depth: 0` for this, and `test/git_lastmod_test.dart` fails if it is
/// ever dropped.
library;

import 'dart:convert';
import 'dart:io';

/// The marker `--format` puts at the start of every date line.
///
/// A NUL is the one byte that cannot occur in a git path, so it is what tells a
/// date line from a path line. Naming it once keeps the `%x00` in the
/// `--format` argument and the check in [parseGitLog] from drifting apart —
/// they are two halves of one wire format, and nothing else would catch it.
const nulPrefix = '\u0000';

/// Committer date of the last commit touching each file under [directory].
///
/// Keys are paths as git prints them, relative to the working directory, so
/// they read as `content/revali/cli/dev.md` when run from the project root.
///
/// One `git log` for the whole site rather than one per page. Returns an empty
/// map if git is unavailable or the command fails; the caller decides what an
/// undated page should fall back to.
Map<String, String> gitDates({String directory = 'content'}) {
  final ProcessResult result;
  try {
    result = Process.runSync('git', [
      'log',
      // A NUL prefix is what separates a date line from a path line. Without it
      // the two are told apart by guessing at the shape of the text, and a file
      // named like a timestamp breaks the parse.
      '--format=$_dateFormat',
      '--name-only',
      // Paths relative to the working directory, so they line up with the keys
      // the caller builds no matter where the project sits in the repository.
      '--relative',
      '--',
      directory,
    ]);
  } on ProcessException {
    return const {};
  }
  if (result.exitCode != 0) return const {};
  return parseGitLog(result.stdout as String);
}

/// The `--format` argument [gitDates] passes, and [parseGitLog] expects.
const _dateFormat = '%x00%cI';

/// Parses `git log --format=%x00%cI --name-only` output into path -> date.
///
/// Split out from [gitDates] because it is the part that can be wrong in an
/// interesting way, and a pure function over a string is testable without a
/// repository to point it at.
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
