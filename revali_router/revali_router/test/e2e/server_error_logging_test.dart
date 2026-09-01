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

  // A 5xx the app wrote is not a crash: the component that chose the status
  // knows why, and a trace per response is paid on the path whose volume is
  // highest exactly when the server has the least to spare.
  group('authored server errors stay quiet', () {
    test('a catcher shedding load with a 503 is not logged', () async {
      late Response response;

      final printed = await capturePrints(() async {
        await testRequest(
          TestRoute(
            catchers: [_SheddingCatcher()],
            handler: (context) async {
              throw _AppException();
            },
          ),
          verifyResponse: (r, context) => response = r,
        );
      });

      // The response the app authored is still delivered as written...
      expect(response.statusCode, HttpStatus.serviceUnavailable);
      expect(response.body.data, {'error': 'shedding'});
      // ...and costs the operator nothing: no line, so no frames formatted.
      expect(printed, isEmpty);
    });

    test('an uncaught HttpError carrying a 5xx is not logged', () async {
      late Response response;

      final printed = await capturePrints(() async {
        await testRequest(
          TestRoute(
            handler: (context) async {
              throw const HttpError.internal(
                code: 'upstream_down',
                message: 'try later',
              );
            },
          ),
          verifyResponse: (r, context) => response = r,
        );
      });

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(printed, isEmpty);
    });

    test('a bare handled() still owes the operator a trace', () async {
      // Claiming an exception without writing a status or a body authors
      // nothing, so the generic 500 that results is still a crash to log.
      final printed = await capturePrints(() async {
        await testRequest(
          TestRoute(
            catchers: [_BareCatcher()],
            handler: (context) async {
              throw _AppException();
            },
          ),
          verifyResponse: (r, context) {
            expect(r.statusCode, HttpStatus.internalServerError);
          },
        );
      });

      expect(printed, hasLength(1));
      expect(printed.single, contains('server_error_logging_test.dart'));
    });

    test('debug: true still logs it, alongside the body detail', () async {
      // Under `revali dev` the console is where the developer is looking, and
      // dev throughput is nobody's bottleneck.
      final printed = await capturePrints(() async {
        await testRequest(
          TestRoute(
            debug: true,
            catchers: [_SheddingCatcher()],
            handler: (context) async {
              throw _AppException();
            },
          ),
          verifyResponse: (r, context) {
            expect(r.statusCode, HttpStatus.serviceUnavailable);
          },
        );
      });

      expect(printed, hasLength(1));
      expect(printed.single, startsWith('Request failed: '));
    });
  });

  group('an empty stack trace', () {
    test('is logged as the error alone, with no frames parsed', () async {
      // An app that throws with `StackTrace.empty` has made that path cheap
      // on purpose; parsing an empty string is not free and formats nothing.
      final printed = await capturePrints(() async {
        await testRequest(
          TestRoute(
            handler: (context) async {
              Error.throwWithStackTrace(
                StateError('no frames'),
                StackTrace.empty,
              );
            },
          ),
          verifyResponse: (r, context) {
            expect(r.statusCode, HttpStatus.internalServerError);
          },
        );
      });

      expect(printed, hasLength(1));
      // Exactly the error line: no trailing newline, no frames after it.
      expect(printed.single, 'Request failed: Bad state: no frames');
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

/// Writes a status and an envelope of its own: an authored response.
base class _SheddingCatcher extends ExceptionCatcher<_AppException> {
  @override
  ExceptionCatcherResult<_AppException> catchException(
    _AppException exception,
    Context context,
  ) =>
      const ExceptionCatcherResult.handled(
        statusCode: HttpStatus.serviceUnavailable,
        body: {'error': 'shedding'},
      );
}

/// Claims the exception but writes nothing, leaving the status to the router.
base class _BareCatcher extends ExceptionCatcher<_AppException> {
  @override
  ExceptionCatcherResult<_AppException> catchException(
    _AppException exception,
    Context context,
  ) =>
      const ExceptionCatcherResult.handled();
}

class _BlockingGuard implements Guard {
  @override
  Future<GuardResult> protect(Context context) async =>
      const GuardResult.block();
}
