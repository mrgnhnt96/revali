import 'dart:async';
import 'dart:io';

import 'package:revali_core/revali_core.dart';
import 'package:test/test.dart';

import 'utils/test_request.dart';

/// Runs [body] with `print` captured, and returns the lines it wrote.
Future<List<String>> capturePrints(Future<void> Function() body) async {
  final printed = <String>[];

  await runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => printed.add(line),
    ),
  );

  return printed;
}

void main() {
  group('server errors reach the log', () {
    test('an exception no catcher claims is logged, not just answered with 500',
        () async {
      late Response response;

      final printed = await capturePrints(() async {
        await testRequest(
          TestRoute(
            // Registered for the app's own type only -- the ordinary way to
            // write a catcher, and the shape that leaves every `dart:io`
            // exception unclaimed.
            catchers: [_AppCatcher()],
            handler: (context) async {
              throw const FileSystemException('boom', 'some/path');
            },
          ),
          verifyResponse: (r, context) => response = r,
        );
      });

      // The caller still learns nothing it should not.
      expect(response.statusCode, HttpStatus.internalServerError);
      expect(response.body.data, 'Internal Server Error');

      // The operator does.
      expect(printed, hasLength(1));
      expect(printed.single, startsWith('Request failed: '));
      expect(printed.single, contains('FileSystemException'));
      expect(printed.single, contains('boom'));
      // A status code with no frames is what made this undiagnosable.
      expect(printed.single, contains('server_error_logging_test.dart'));
    });

    test('debug: true logs it too, as well as putting it in the body',
        () async {
      late Response response;

      final printed = await capturePrints(() async {
        await testRequest(
          TestRoute(
            debug: true,
            handler: (context) async {
              throw const FileSystemException('boom', 'some/path');
            },
          ),
          verifyResponse: (r, context) => response = r,
        );
      });

      // debug controls what the caller is shown...
      expect('${response.body.data}', contains('FileSystemException'));
      // ...not whether the operator is told at all.
      expect(printed, hasLength(1));
      expect(printed.single, contains('FileSystemException'));
    });

    test('an error thrown while resolving the route is logged', () async {
      final printed = await capturePrints(() async {
        await testRequest(
          TestRoute(
            handler: (context) async {
              throw StateError('from a dependency');
            },
          ),
          verifyResponse: (r, context) {},
        );
      });

      expect(printed, hasLength(1));
      expect(printed.single, contains('from a dependency'));
    });
  });

  group('client errors stay quiet', () {
    test('an exception a catcher handles into a 4xx is not logged', () async {
      late Response response;

      final printed = await capturePrints(() async {
        await testRequest(
          TestRoute(
            catchers: [_AppCatcher()],
            handler: (context) async {
              throw _AppException();
            },
          ),
          verifyResponse: (r, context) => response = r,
        );
      });

      expect(response.statusCode, HttpStatus.unauthorized);
      expect(printed, isEmpty);
    });

    test('a route that does not exist is not logged', () async {
      final printed = await capturePrints(() async {
        await testRequest(
          TestRoute(
            path: 'known',
            requestPath: 'nothing-here',
            handler: (context) async {},
          ),
          verifyResponse: (r, context) {
            expect(r.statusCode, HttpStatus.notFound);
          },
        );
      });

      expect(printed, isEmpty);
    });

    test('a guard refusing a caller is not logged', () async {
      final printed = await capturePrints(() async {
        await testRequest(
          TestRoute(guards: [_BlockingGuard()]),
          verifyResponse: (r, context) {
            expect(r.statusCode, HttpStatus.forbidden);
          },
        );
      });

      expect(printed, isEmpty);
    });
  });
}

class _AppException implements Exception {}

base class _AppCatcher extends ExceptionCatcher<_AppException> {
  @override
  ExceptionCatcherResult<_AppException> catchException(
    _AppException exception,
    Context context,
  ) =>
      const ExceptionCatcherResult.handled(
        statusCode: HttpStatus.unauthorized,
      );
}

class _BlockingGuard implements Guard {
  @override
  Future<GuardResult> protect(Context context) async =>
      const GuardResult.block();
}
