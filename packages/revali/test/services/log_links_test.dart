import 'package:revali/services/log_links.dart';
import 'package:test/test.dart';

/// Which runs of a log line name somewhere a browser could go.
///
/// Kept separate from the pane that draws them because this is the half with
/// all the judgement in it — which methods are openable, what a wildcard host
/// becomes, what happens with no base — and none of it needs a terminal.
void main() {
  group('absolute URLs', () {
    test('finds the address in a Serving at line', () {
      final links = findLinks('Serving at http://0.0.0.0:8080/api');

      expect(links, hasLength(1));
      expect(links.single.start, 'Serving at '.length);
      expect(links.single.end, 'Serving at http://0.0.0.0:8080/api'.length);
    });

    test('rewrites a wildcard host to something connectable', () {
      // The whole point: `0.0.0.0` means "every interface" to a listening
      // socket and nothing at all to a browser.
      final links = findLinks('Serving at http://0.0.0.0:8080/api');

      expect(links.single.url, 'http://localhost:8080/api');
    });

    test('rewrites the IPv6 wildcard too', () {
      expect(
        findLinks('Serving at http://[::]:8080/api').single.url,
        'http://localhost:8080/api',
      );
    });

    test('leaves a real host alone', () {
      expect(
        findLinks('listening on http://127.0.0.1:52345/abc=/').single.url,
        'http://127.0.0.1:52345/abc=/',
      );
    });

    test('keeps a URL that carries another in its query whole', () {
      // The DevTools line. Stopping at the second `http://` opens half of it.
      const line =
          'The Dart DevTools debugger is available at: '
          'http://127.0.0.1:9100?uri=http://127.0.0.1:52345/abc=/';

      final links = findLinks(line);

      expect(links, hasLength(1));
      expect(
        links.single.url,
        'http://127.0.0.1:9100?uri=http://127.0.0.1:52345/abc=/',
      );
    });

    test('drops the full stop a sentence ended with', () {
      final links = findLinks('see http://localhost:8080/api.');

      expect(links.single.url, 'http://localhost:8080/api');
    });

    test('keeps a balanced bracket inside the URL', () {
      final links = findLinks('at http://localhost:8080/a(b)');

      expect(links.single.url, 'http://localhost:8080/a(b)');
    });

    test('gives back an unbalanced closing bracket', () {
      final links = findLinks('(see http://localhost:8080/api)');

      expect(links.single.url, 'http://localhost:8080/api');
    });

    test('a line with no URL has no links', () {
      expect(findLinks('⠋ Retrieving dependencies...'), isEmpty);
    });
  });

  group('route paths', () {
    const base = 'http://0.0.0.0:8080/api';

    test('a GET row resolves to the base plus the path', () {
      final links = findLinks(
        'GET       -> /billing/invoices',
        baseUrl: base,
      );

      expect(links, hasLength(1));
      expect(links.single.url, 'http://localhost:8080/api/billing/invoices');
    });

    test('the link covers the path and nothing else', () {
      // The method and the arrow are not clickable: the run has to be the
      // thing the user is pointing at.
      const line = 'GET       -> /billing/invoices';
      final links = findLinks(line, baseUrl: base);

      expect(line.substring(links.single.start, links.single.end),
          '/billing/invoices');
    });

    test('without a base there is nothing to resolve against', () {
      // A service that has not announced an address yet. A click here must do
      // nothing rather than open a guess.
      expect(findLinks('GET       -> /billing/invoices'), isEmpty);
    });

    test('a POST row is not clickable', () {
      // A browser navigation is a GET whatever the row says.
      expect(findLinks('POST      -> /billing/invoices', baseUrl: base),
          isEmpty);
    });

    test('every non-GET method is left alone', () {
      for (final method in [
        'POST',
        'PUT',
        'DELETE',
        'PATCH',
        'HEAD',
        'OPTIONS',
        'TRACE',
        'CONNECT',
        'WS',
      ]) {
        expect(
          findLinks('${method.padRight(10)}-> /billing/invoices',
              baseUrl: base),
          isEmpty,
          reason: '$method must not be clickable',
        );
      }
    });

    test('a GET (SSE) row is clickable', () {
      // It is a GET; a browser opening it gets the raw event stream.
      final links = findLinks('GET (SSE) -> /events', baseUrl: base);

      expect(links.single.url, 'http://localhost:8080/api/events');
    });

    test('a path with a :param segment is not clickable', () {
      // A template, not an address. There is nothing here that could fill it.
      expect(findLinks('GET       -> /users/:id', baseUrl: base), isEmpty);
      expect(
        findLinks('GET       -> /users/:id/orders', baseUrl: base),
        isEmpty,
      );
    });

    test('a base with no prefix still joins cleanly', () {
      expect(
        findLinks('GET       -> /health', baseUrl: 'http://0.0.0.0:8080')
            .single
            .url,
        'http://localhost:8080/health',
      );
    });

    test('a trailing slash on the base does not double up', () {
      expect(
        findLinks('GET       -> /health', baseUrl: 'http://0.0.0.0:8080/api/')
            .single
            .url,
        'http://localhost:8080/api/health',
      );
    });

    test('prose containing an arrow is not a route row', () {
      expect(
        findLinks('note: GET -> /billing is the old name', baseUrl: base),
        isEmpty,
      );
    });
  });

  group('servingAddress', () {
    test('reads the address off the line', () {
      expect(
        servingAddress('Serving at http://0.0.0.0:8080/api'),
        'http://0.0.0.0:8080/api',
      );
    });

    test('reads it through the colour the child wrapped it in', () {
      // `revali dev` hands the line to `logger.success`, so by the time it
      // reaches this side it no longer begins with the `S`.
      expect(
        servingAddress('\x1B[92mServing at http://0.0.0.0:8080/api\x1B[0m'),
        'http://0.0.0.0:8080/api',
      );
    });

    test('returns what the child wrote, not the rewritten form', () {
      // The displayed text is the truth about what the service bound.
      // Rewriting happens only where a URL is launched.
      expect(
        servingAddress('Serving at http://0.0.0.0:8080'),
        startsWith('http://0.0.0.0'),
      );
    });

    test('a line that is not a serving line has no address', () {
      expect(servingAddress('GET       -> /billing'), isNull);
      expect(servingAddress('Serving at '), isNull);
      expect(servingAddress('Serving at nonsense'), isNull);
    });
  });
}
