import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:revali_router/src/endpoint/endpoint_context_impl.dart';
import 'package:revali_router/src/exception_catcher/exception_catcher_context_impl.dart';
import 'package:revali_router/src/exception_catcher/exception_catcher_meta_impl.dart';
import 'package:revali_router/src/exceptions/guard_stop_exception.dart';
import 'package:revali_router/src/exceptions/invalid_handler_result_exception.dart';
import 'package:revali_router/src/exceptions/middleware_stop_exception.dart';
import 'package:revali_router/src/exceptions/missing_handler_exception.dart';
import 'package:revali_router/src/exceptions/route_not_found_exception.dart';
import 'package:revali_router/src/guard/guard_context_impl.dart';
import 'package:revali_router/src/guard/guard_meta_impl.dart';
import 'package:revali_router/src/interceptor/interceptor_context_impl.dart';
import 'package:revali_router/src/interceptor/interceptor_meta_impl.dart';
import 'package:revali_router/src/middleware/middleware_context_impl.dart';
import 'package:revali_router/src/request/mutable_request_impl.dart';
import 'package:revali_router/src/request/request_context_impl.dart';
import 'package:revali_router/src/request/websocket_request_context_impl.dart';
import 'package:revali_router/src/response/canned_response.dart';
import 'package:revali_router/src/response/default_responses.dart';
import 'package:revali_router/src/response/mutable_response_impl.dart';
import 'package:revali_router/src/response/simple_response.dart';
import 'package:revali_router/src/route/base_route.dart';
import 'package:revali_router/src/route/route_match.dart';
import 'package:revali_router/src/route/route_modifiers_impl.dart';
import 'package:revali_router_core/revali_router_core.dart';
import 'package:stack_trace/stack_trace.dart';

import '../route/web_socket_route.dart';

part 'body_for_error.dart';
part 'debug_response.dart';
part 'execute.dart';
part 'find.dart';
part 'handle_web_socket.dart';
part 'is_origin_allowed.dart';
part 'override_response.dart';
part 'router.g.dart';
part 'run_catchers.dart';
part 'run_guards.dart';
part 'run_middlewares.dart';

class Router extends Equatable {
  Router({
    required this.routes,
    RouteModifiers? globalModifiers,
    Set<Reflect> reflects = const {},
    this.observers = const [],
    this.debug = false,
    this.defaultResponses = const DefaultResponses(),
  })  : _reflects = reflects,
        _globalModifiers = globalModifiers;

  final List<Observer> observers;
  final List<BaseRoute> routes;
  final Set<Reflect> _reflects;
  final RouteModifiers? _globalModifiers;
  final bool debug;
  final DefaultResponses defaultResponses;

  /// Handles an HTTP request.
  ///
  /// Passes the request to the [handle] method.
  Future<ReadOnlyResponse> handleHttpRequest(HttpRequest request) async {
    final context = RequestContextImpl.fromRequest(request);
    return handle(context);
  }

  Future<ReadOnlyResponse> handle(RequestContext context) async {
    final responseCompleter = Completer<ReadOnlyResponse>();

    try {
      final request = MutableRequestImpl.fromRequest(context);

      for (final observer in observers) {
        observer.see(request, responseCompleter.future);
      }

      final result = await _handle(request);

      responseCompleter.complete(result);

      return result;
    } catch (e, stackTrace) {
      final response = _debugResponse(
        defaultResponses.internalServerError,
        error: e,
        stackTrace: stackTrace,
      );

      responseCompleter.complete(response);

      return response;
    }
  }

  Future<ReadOnlyResponse> _handle(MutableRequestImpl request) async {
    final segments = request.segments;

    final match = find(
      segments: segments,
      routes: routes,
      method: request.method,
    );

    if (match == null) {
      return _debugResponse(
        defaultResponses.notFound,
        error: RouteNotFoundException(
          method: request.method,
          path: segments.join('/'),
        ),
        stackTrace: StackTrace.current,
      );
    }

    final RouteMatch(:route, :pathParameters) = match;
    final globalModifiers = _globalModifiers ?? RouteModifiersImpl();

    if (request.method == 'OPTIONS') {
      return CannedResponse.options(
        allowedMethods: route.allowedMethods,
      );
    }

    if (route.redirect case final redirect?) {
      return CannedResponse.redirect(
        redirect.path,
        statusCode: redirect.code,
      );
    }

    if (isOriginAllowed(
      request,
      route,
      globalAllowedOrigins: globalModifiers.allowedOrigins?.origins,
      globalAllowedHeaders: globalModifiers.allowedHeaders?.headers,
    )
        case final response?) {
      return response;
    }

    request.pathParameters = pathParameters;

    final response = MutableResponseImpl(requestHeaders: request.headers);

    final directMeta = route.getMeta();
    final inheritedMeta = route.getMeta(inherit: true);
    globalModifiers.getMeta(handler: inheritedMeta);
    final dataHandler = DataHandler();
    final reflectHandler = ReflectHandler(_reflects);

    try {
      final result = await execute(
        route: route,
        globalModifiers: globalModifiers,
        request: request,
        response: response,
        dataHandler: dataHandler,
        directMeta: directMeta,
        inheritedMeta: inheritedMeta,
        reflectHandler: reflectHandler,
      );

      return result;
    } catch (e, stackTrace) {
      if (e is! Exception) {
        return _debugResponse(
          defaultResponses.internalServerError,
          error: e,
          stackTrace: stackTrace,
        );
      }

      if (await runCatcher(
        [
          ...route.allCatchers,
          ...globalModifiers.catchers,
        ],
        e: e,
        stackTrace: stackTrace,
        request: request,
        response: response,
        dataHandler: dataHandler,
        directMeta: directMeta,
        inheritedMeta: inheritedMeta,
        route: route,
      )
          case final response?) {
        return response;
      }

      return _debugResponse(
        defaultResponses.internalServerError,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  List<Object?> get props => _$props;
}
