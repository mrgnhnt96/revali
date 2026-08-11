/// The search index model and ranking, shared by the UI and its tests.
///
/// Kept out of `components/search.dart` so the ranking can be exercised
/// directly against the real `web/search-index.json` — see
/// `test/search_index_test.dart`. Nothing here touches the DOM.
library;

List<String> tokenize(String query) =>
    query.toLowerCase().split(RegExp(r'\s+')).where((token) => token.isNotEmpty).toList();

/// Ranks [index] against [query], best first.
///
/// Every token must match somewhere in a section for it to be a hit (AND, not
/// OR) — with over a thousand sections, OR matching turns a two-word query into
/// noise.
List<SearchHit> searchIndex(List<SearchDoc> index, String query) {
  final tokens = tokenize(query);
  if (tokens.isEmpty) return const [];

  final phrase = query.trim().toLowerCase();
  final hits = <SearchHit>[];

  for (final doc in index) {
    final title = doc.title.toLowerCase();
    final description = doc.description.toLowerCase();
    final group = doc.group.toLowerCase();
    // `/constructs/revali_server/core/pipes` — searching "pipes" or
    // "revali_server" should find the page whose URL says so even when the
    // prose never repeats it.
    final url = doc.url.toLowerCase();

    final docHits = <SearchHit>[];

    for (final section in doc.sections) {
      final heading = section.heading?.toLowerCase() ?? '';
      final body = section.body.toLowerCase();

      var score = 0;
      var matchesAll = true;

      for (final token in tokens) {
        var tokenScore = 0;
        if (title.contains(token)) tokenScore += title.startsWith(token) ? 46 : 30;
        if (heading.contains(token)) tokenScore += 18;
        if (description.contains(token)) tokenScore += 10;
        if (url.contains(token)) tokenScore += 8;
        if (body.contains(token)) tokenScore += 6;
        if (group.contains(token)) tokenScore += 4;

        if (tokenScore == 0) {
          matchesAll = false;
          break;
        }
        score += tokenScore;
      }
      if (!matchesAll) continue;

      // Whole-phrase matches. Without these, "exception catcher" ranks a deep
      // subsection above the Exception Catchers page itself, because per-token
      // scores alone cannot tell a page *about* the topic from a page that
      // merely mentions it.
      if (title.startsWith(phrase)) score += 70;
      if (title.contains(phrase)) score += 40;
      if (heading.contains(phrase)) score += 20;
      if (body.contains(phrase)) score += 12;

      // The intro section stands in for the page as a whole, so it should win
      // ties against that page's own subsections.
      if (section.heading == null) score += 14;

      // Deprioritise the section overviews. Nine pages on this site are titled
      // exactly "Overview", and without this a query matching one of them
      // outranks the specific page the reader wanted.
      if (title == 'overview') score -= 12;

      docHits.add(
        SearchHit(
          href: section.anchor == null ? doc.url : '${doc.url}#${section.anchor}',
          title: doc.title,
          group: doc.group,
          heading: section.heading,
          snippet: snippetFor(section.body, tokens),
          score: score,
        ),
      );
    }

    if (docHits.isEmpty) continue;
    docHits.sort((a, b) => b.score.compareTo(a.score));
    // Cap per page so one long page cannot crowd out every other result.
    hits.addAll(docHits.take(3));
  }

  hits.sort((a, b) => b.score.compareTo(a.score));
  return hits.take(24).toList();
}

/// A window of [body] around the first token match.
String snippetFor(String body, List<String> tokens) {
  if (body.isEmpty) return '';

  final lower = body.toLowerCase();
  var at = -1;
  for (final token in tokens) {
    final found = lower.indexOf(token);
    if (found >= 0 && (at < 0 || found < at)) at = found;
  }
  if (at < 0) at = 0;

  var start = at - 60;
  if (start < 0) start = 0;
  // Avoid cutting mid-word on the left.
  if (start > 0) {
    final space = body.indexOf(' ', start);
    if (space >= 0 && space < at) start = space + 1;
  }

  var end = start + 190;
  if (end > body.length) end = body.length;

  final prefix = start > 0 ? '…' : '';
  final suffix = end < body.length ? '…' : '';
  return '$prefix${body.substring(start, end).trim()}$suffix';
}

/// One page in the index.
final class SearchDoc {
  const SearchDoc({
    required this.url,
    required this.title,
    required this.description,
    required this.group,
    required this.sections,
  });

  factory SearchDoc.fromJson(Map<String, Object?> json) => SearchDoc(
    url: json['u']! as String,
    title: json['t']! as String,
    description: json['d'] as String? ?? '',
    group: json['g'] as String? ?? '',
    sections: [
      for (final section in json['s']! as List)
        SearchSection.fromJson(section as Map<String, Object?>),
    ],
  );

  final String url;
  final String title;
  final String description;

  /// The section label shown above a result — `Revali`, `Constructs`, or
  /// `Create Constructs`.
  final String group;
  final List<SearchSection> sections;
}

/// One heading-delimited chunk of a page.
final class SearchSection {
  const SearchSection({this.heading, this.anchor, required this.body});

  factory SearchSection.fromJson(Map<String, Object?> json) => SearchSection(
    heading: json['h'] as String?,
    anchor: json['a'] as String?,
    body: json['b'] as String? ?? '',
  );

  final String? heading;
  final String? anchor;
  final String body;
}

/// A scored result row.
final class SearchHit {
  const SearchHit({
    required this.href,
    required this.title,
    required this.group,
    required this.heading,
    required this.snippet,
    required this.score,
  });

  final String href;
  final String title;
  final String group;
  final String? heading;
  final String snippet;
  final int score;
}
