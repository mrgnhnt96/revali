import 'package:revali/services/ansi.dart';

/// A run of a log line that names somewhere a browser could actually go.
///
/// [start] and [end] index the line with its escape sequences already stripped
/// — which is the same string the pane paints, so a range here is a range of
/// *visible characters*. [url] is the address to launch, which is not
/// necessarily the text: a wildcard bind address is displayed as the child
/// wrote it and rewritten on the way out. See [launchableUrl].
class LogLink {
  const LogLink({required this.start, required this.end, required this.url});

  /// Inclusive, into the ANSI-stripped line.
  final int start;

  /// Exclusive.
  final int end;

  /// Where clicking it goes. Always absolute, always launchable.
  final String url;

  @override
  bool operator ==(Object other) =>
      other is LogLink &&
      other.start == start &&
      other.end == end &&
      other.url == url;

  @override
  int get hashCode => Object.hash(start, end, url);

  @override
  String toString() => 'LogLink($start..$end -> $url)';
}

/// Every clickable run in [line], left to right and never overlapping.
///
/// [line] is expected to be ANSI-stripped already — the caller has to strip it
/// anyway to paint it, and doing it twice would let the two disagree about
/// where a run starts.
///
/// [baseUrl] is what the service announced it is listening on, or null while it
/// has not announced anything yet. Without one a bare route path has no base
/// and is *not* returned: a click that cannot be resolved must do nothing,
/// because opening a guess is worse than opening nothing.
List<LogLink> findLinks(String line, {String? baseUrl}) {
  final links = <LogLink>[
    ..._absoluteUrls(line),
    ...?_routePath(line, baseUrl: baseUrl),
  ]..sort((a, b) => a.start.compareTo(b.start));

  // A route row cannot also contain an absolute URL, so this only ever drops
  // something if a pattern is widened later. Cheap insurance against two
  // overlapping ranges reaching the renderer, which would paint one run twice.
  final resolved = <LogLink>[];
  for (final link in links) {
    if (resolved.isNotEmpty && link.start < resolved.last.end) continue;
    resolved.add(link);
  }

  return resolved;
}

/// `http://…` and `https://…` anywhere in the line.
///
/// Greedy to the first whitespace on purpose. The DevTools line is
/// `…available at: http://127.0.0.1:9100?uri=http://127.0.0.1:52345/abc=/` —
/// one URL that happens to carry another in its query, and stopping at the
/// second `http://` would open half of it.
Iterable<LogLink> _absoluteUrls(String line) sync* {
  for (final match in _urlPattern.allMatches(line)) {
    var end = match.end;

    // Trailing punctuation belongs to the sentence, not the address. Brackets
    // are only given back when they are unbalanced — `…(see http://x/a(b))`
    // ends one paren deep, and a URL genuinely may contain them.
    while (end > match.start) {
      final char = line[end - 1];
      if (_trailingPunctuation.contains(char)) {
        end--;
        continue;
      }
      if (char == ')' || char == ']') {
        final open = char == ')' ? '(' : '[';
        final text = line.substring(match.start, end);
        if (_count(text, open) < _count(text, char)) {
          end--;
          continue;
        }
      }
      break;
    }

    if (end <= match.start) continue;

    final text = line.substring(match.start, end);
    if (launchableUrl(text) case final url?) {
      yield LogLink(start: match.start, end: end, url: url);
    }
  }
}

/// The path of a route-table row, if this line is one.
///
/// `revali dev` prints these from `printParsedRoutes` as
/// `<METHOD padded to 10><grey '-> '><path>` — so the shape is fixed and the
/// path is the whole of the tail.
///
/// **Only `GET` rows are clickable.** A click opens a URL in a browser, and a
/// browser navigation is a GET whatever the row says; making a `POST` row
/// clickable would offer to do the thing the line describes and then do a
/// different thing to the same path. At best that is a 404 or a 405, and at
/// worst it reaches a handler that was never meant to be reachable by
/// navigation. `GET (SSE)` is included because it *is* a GET — a browser
/// opening one gets the raw event stream, which is what the row promises.
///
/// A path carrying a `:param` segment is also left alone. It is a template
/// rather than an address, and `/users/:id` is not a URL anyone wants opened
/// literally; there is nothing on this side that could fill it in.
Iterable<LogLink>? _routePath(String line, {required String? baseUrl}) {
  // No announced address means no base. Reassembling one from the plan's port
  // would miss the app prefix, which only the child knows.
  if (baseUrl == null) return null;

  final match = _routeRowPattern.firstMatch(line);
  if (match == null) return null;

  final path = match.group(1)!;
  if (path.split('/').any((segment) => segment.startsWith(':'))) return null;

  final url = launchableUrl('${_withoutTrailingSlash(baseUrl)}$path');
  if (url == null) return null;

  // The pattern is anchored at both ends and the path is its tail, so the path
  // runs to the end of the line. `Match` exposes no per-group offsets, and
  // searching for the path text again could find an earlier copy of it.
  return [LogLink(start: match.end - path.length, end: match.end, url: url)];
}

/// [raw] as something a browser can be pointed at, or null if it is not a URL.
///
/// A wildcard bind address is rewritten. `0.0.0.0` and `::` mean "every
/// interface" to a listening socket and mean nothing at all to a client — a
/// browser given `http://0.0.0.0:8080` either fails outright or is quietly
/// rescued by the OS, and neither is something to rely on. The *displayed* text
/// is left exactly as the child wrote it: it is the truth about what the
/// service bound, and rewriting it on screen would be this side lying about the
/// other side's output.
String? launchableUrl(String raw) {
  final uri = Uri.tryParse(raw);
  if (uri == null) return null;
  if (!uri.hasScheme || !_launchableSchemes.contains(uri.scheme)) return null;
  if (uri.host.isEmpty) return null;

  if (_wildcardHosts.contains(uri.host)) {
    return uri.replace(host: 'localhost').toString();
  }

  return uri.toString();
}

/// The address a service announced it is listening on, read off its own
/// `Serving at …` line, or null if [line] is not one.
///
/// Read from the child's output rather than reassembled from the plan's port
/// because the line carries the app *prefix* too — `revali up` assigns the port
/// but has no idea the app mounts itself under `/api`, and a base without the
/// prefix sends every route click to a 404.
///
/// Returned as written, wildcard host and all. Rewriting happens where a URL is
/// launched ([launchableUrl]), so there is one place that decides it.
String? servingAddress(String line) {
  final plain = stripAnsi(line);
  final index = plain.indexOf(_servingMarker);
  if (index == -1) return null;

  final rest = plain.substring(index + _servingMarker.length).trim();
  if (rest.isEmpty) return null;

  // Whitespace-delimited: `mason_logger` may have appended nothing, but a
  // future suffix must not become part of the address.
  final address = rest.split(RegExp(r'\s')).first;

  return launchableUrl(address) == null ? null : address;
}

String _withoutTrailingSlash(String url) =>
    url.endsWith('/') ? url.substring(0, url.length - 1) : url;

int _count(String text, String char) => text.split(char).length - 1;

/// See `ServiceSession`'s own marker — the same string, matched anywhere in the
/// line for the same reason: the child hands it to `logger.success`, which
/// wraps it in colour.
const _servingMarker = 'Serving at ';

/// Hosts that mean "every interface" and so cannot be connected to.
///
/// `Uri` normalises `[::]` to `::`, so the bracketed form does not need its own
/// entry; the fully-written-out IPv6 form does.
const _wildcardHosts = {'0.0.0.0', '::', '0:0:0:0:0:0:0:0'};

/// Schemes worth handing to a browser. A `ws://` from a route table is a real
/// address but not one a browser opens by navigation.
const _launchableSchemes = {'http', 'https'};

const _trailingPunctuation = '.,;:!?\'"`';

final _urlPattern = RegExp(r"""https?://[^\s<>"']+""");

/// `GET       -> /billing/invoices`, and the SSE variant `GET (SSE)`.
///
/// Anchored at the start of the line: the pane strips nothing off the front, so
/// a route row begins with its method. Anything else mentioning `-> ` mid-line
/// is prose and must not be mistaken for a route.
final _routeRowPattern = RegExp(r'^GET(?: \(SSE\))?\s+-> (/\S*)$');
