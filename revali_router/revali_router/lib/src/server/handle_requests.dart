// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:revali_router/src/request/request_context_impl.dart';
import 'package:revali_router/src/response/simple_response.dart';
import 'package:revali_router/src/response_handler/default_response_handler.dart';
import 'package:revali_router/src/router/router.dart';
import 'package:revali_router_core/revali_router_core.dart';

/// Serves HTTP requests from [server] using [handler] / [responseHandler].
///
/// Prefer [handleRouterRequests] in production — it performs a single route
/// Find per request instead of resolving the response handler separately.
///
/// Each request is handled concurrently. Failures resolving the response
/// handler no longer abandon the connection — a 500 is written and the
/// socket is closed so the accept loop stays healthy under load.
Future<void> handleRequests(
  HttpServer server,
  Future<Response> Function(RequestContext context) handler,
  Future<ResponseHandler> Function(RequestContext context) responseHandler,
  void Function() close, {
  TrustedProxy trustedProxy = const TrustedProxy(),
}) async {
  try {
    await for (final request in server) {
      // Detach per-request work so a slow handler cannot stall accept().
      unawaited(
        _serveRequest(
          request: request,
          handler: handler,
          responseHandler: responseHandler,
          trustedProxy: trustedProxy,
        ),
      );
    }

    close();
  } catch (e, st) {
    // Accept-loop failures are fatal for this listener, but must not escape
    // silently — log and invoke [close] so hot-reload / process supervision
    // can recover.
    print('HTTP accept loop terminated: $e\n$st');
    try {
      close();
    } catch (_) {}
  }
}

/// Serves HTTP requests using [Router.handleRequest] (single route Find).
Future<void> handleRouterRequests(
  HttpServer server,
  Router router,
  void Function() close,
) async {
  try {
    await for (final request in server) {
      unawaited(
        router.handleRequest(request).catchError((Object e, StackTrace st) {
          print('Request failed: $e\n$st');
          return _failClosed(
            request: request,
            context: RequestContextImpl.fromRequest(
              request,
              trustedProxy: router.trustedProxy,
            ),
            body: 'Internal Server Error (ROOT)',
          );
        }),
      );
    }

    close();
  } catch (e, st) {
    print('HTTP accept loop terminated: $e\n$st');
    try {
      close();
    } catch (_) {}
  }
}

Future<void> _serveRequest({
  required HttpRequest request,
  required Future<Response> Function(RequestContext context) handler,
  required Future<ResponseHandler> Function(RequestContext context)
      responseHandler,
  required TrustedProxy trustedProxy,
}) async {
  final context = RequestContextImpl.fromRequest(
    request,
    trustedProxy: trustedProxy,
  );

  late final ResponseHandler responseSender;
  try {
    responseSender = await responseHandler(context);
  } catch (e, st) {
    print('Failed to get response handler: $e\n$st');
    await _failClosed(
      request: request,
      context: context,
      body: 'Internal Server Error (handler resolve)',
    );
    return;
  }

  try {
    final response = await handler(context);
    await responseSender.handle(response, context, request.response);
  } catch (e, st) {
    print('Request failed: $e\n$st');
    try {
      await responseSender.handle(
        SimpleResponse(500, body: 'Internal Server Error (ROOT)'),
        context,
        request.response,
      );
    } catch (sendError) {
      print('Failed to send error response: $sendError');
      await _failClosed(
        request: request,
        context: context,
        body: 'Internal Server Error (ROOT)',
      );
    }
  }
}

Future<void> _failClosed({
  required HttpRequest request,
  required RequestContext context,
  required String body,
}) async {
  try {
    await const DefaultResponseHandler().handle(
      SimpleResponse(500, body: body),
      context,
      request.response,
    );
  } catch (_) {
    try {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write(body);
      await request.response.close();
    } catch (_) {
      // Connection already gone.
    }
    try {
      await context.close();
    } catch (_) {}
  }
}
