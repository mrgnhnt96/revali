import 'dart:convert';
import 'dart:io';

/// Asks pub.dev which versions of each package are actually published.
///
/// Uses `dart:io` rather than `package:http` so the release script gains no
/// new dependency for one GET per package.
///
/// A package maps to `null` when the lookup failed and to an empty set when
/// the registry answered and has nothing. Callers must not collapse the two:
/// a network blip would otherwise read as "none of these were ever
/// published", which is the loudest possible false alarm and the fastest way
/// to teach someone to ignore the warning.
///
/// Never throws. A release must not be blocked by the registry being
/// unreachable -- the answer degrades to "unknown", which is reported.
Future<Map<String, Set<String>?>> fetchPublishedVersions(
  Iterable<String> packageNames, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final client = HttpClient()..connectionTimeout = timeout;
  final results = <String, Set<String>?>{};

  try {
    for (final name in packageNames) {
      results[name] = await _fetchOne(client, name, timeout);
    }
  } finally {
    client.close(force: true);
  }

  return results;
}

Future<Set<String>?> _fetchOne(
  HttpClient client,
  String name,
  Duration timeout,
) async {
  try {
    final uri = Uri.https('pub.dev', '/api/packages/$name');
    final request = await client.getUrl(uri).timeout(timeout);
    final response = await request.close().timeout(timeout);

    // A package that has never been published is a 404, and that is an
    // answer, not a failure -- it is precisely the case worth catching.
    if (response.statusCode == HttpStatus.notFound) {
      await response.drain<void>();
      return <String>{};
    }

    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      return null;
    }

    final body = await response.transform(utf8.decoder).join().timeout(timeout);
    final decoded = jsonDecode(body);

    if (decoded is! Map || decoded['versions'] is! List) {
      return null;
    }

    return {
      for (final entry in decoded['versions'] as List)
        if (entry is Map && entry['version'] is String)
          entry['version'] as String,
    };
  } catch (_) {
    // Anything at all -- DNS, TLS, timeout, malformed JSON -- is "unknown".
    return null;
  }
}
