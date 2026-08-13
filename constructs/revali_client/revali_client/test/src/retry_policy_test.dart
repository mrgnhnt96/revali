import 'package:revali_client/revali_client.dart';
import 'package:test/test.dart';

HttpRequest requestFor(String method, {Stream<List<int>>? bodyStream}) =>
    HttpRequest(
      method: method,
      url: Uri.parse('http://example.test/thing'),
      bodyStream: bodyStream,
    );

HttpResponse responseFor(
  int status, {
  Map<String, String> headers = const {},
}) => HttpResponse(
  request: requestFor('GET'),
  statusCode: status,
  headers: headers,
  stream: const Stream.empty(),
  persistentConnection: false,
  reasonPhrase: null,
  contentLength: 0,
);

void main() {
  group('RetryPolicy.none', () {
    test('is disabled', () {
      expect(const RetryPolicy.none().enabled, isFalse);
      expect(const RetryPolicy.none().allows(requestFor('GET')), isFalse);
    });
  });

  group('allows', () {
    const policy = RetryPolicy();

    test('permits idempotent methods', () {
      for (final method in ['GET', 'HEAD', 'OPTIONS', 'PUT', 'DELETE']) {
        expect(policy.allows(requestFor(method)), isTrue, reason: method);
      }
    });

    test('refuses POST and PATCH', () {
      // Retrying a POST that reached the server and failed on the way back
      // creates the resource twice.
      expect(policy.allows(requestFor('POST')), isFalse);
      expect(policy.allows(requestFor('PATCH')), isFalse);
    });

    test('is case insensitive about the method', () {
      expect(policy.allows(requestFor('get')), isTrue);
    });

    test('refuses a streamed body even on an idempotent method', () {
      // The stream is consumed as it is sent, so a second attempt would
      // transmit nothing at all.
      expect(
        policy.allows(
          requestFor('PUT', bodyStream: const Stream<List<int>>.empty()),
        ),
        isFalse,
      );
    });
  });

  group('shouldRetryResponse', () {
    const policy = RetryPolicy();

    test('retries transient upstream failures', () {
      for (final status in [502, 503, 504]) {
        expect(
          policy.shouldRetryResponse(responseFor(status), 1),
          isTrue,
          reason: '$status',
        );
      }
    });

    test('does not retry a client error', () {
      // A 400 or 404 says the same thing next time; retrying only multiplies
      // load during an incident.
      for (final status in [200, 400, 404, 500]) {
        expect(
          policy.shouldRetryResponse(responseFor(status), 1),
          isFalse,
          reason: '$status',
        );
      }
    });

    test('stops at maxAttempts', () {
      expect(policy.shouldRetryResponse(responseFor(503), 2), isTrue);
      expect(policy.shouldRetryResponse(responseFor(503), 3), isFalse);
    });
  });

  group('delayFor', () {
    test('backs off exponentially', () {
      const policy = RetryPolicy(initialDelay: Duration(milliseconds: 100));

      expect(policy.delayFor(1), const Duration(milliseconds: 100));
      expect(policy.delayFor(2), const Duration(milliseconds: 200));
      expect(policy.delayFor(3), const Duration(milliseconds: 400));
    });

    test('caps at maxDelay', () {
      const policy = RetryPolicy(
        initialDelay: Duration(seconds: 1),
        maxDelay: Duration(seconds: 2),
      );

      expect(policy.delayFor(5), const Duration(seconds: 2));
    });

    test('prefers Retry-After when the server sent one', () {
      const policy = RetryPolicy(initialDelay: Duration(milliseconds: 100));
      final response = responseFor(503, headers: {'retry-after': '7'});

      // A server that says when it will be ready knows better than a curve.
      expect(policy.delayFor(1, response), const Duration(seconds: 7));
    });

    test('ignores a Retry-After it cannot trust', () {
      const policy = RetryPolicy(initialDelay: Duration(milliseconds: 100));

      // The HTTP-date form is deliberately not guessed at against a clock
      // that may not agree with the server's.
      for (final value in ['Wed, 21 Oct 2015 07:28:00 GMT', 'soon', '-5']) {
        expect(
          policy.delayFor(1, responseFor(503, headers: {'retry-after': value})),
          const Duration(milliseconds: 100),
          reason: value,
        );
      }
    });

    test('ignores Retry-After when told not to honour it', () {
      const policy = RetryPolicy(
        initialDelay: Duration(milliseconds: 100),
        honorRetryAfter: false,
      );

      expect(
        policy.delayFor(1, responseFor(503, headers: {'retry-after': '7'})),
        const Duration(milliseconds: 100),
      );
    });
  });
}
