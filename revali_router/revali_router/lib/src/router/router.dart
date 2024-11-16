import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:http_parser/http_parser.dart';
import 'package:revali_annotations/revali_annotations.dart' hide WebSocket;
import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:revali_router/src/endpoint/endpoint_context_impl.dart';
import 'package:revali_router/src/exception_catcher/exception_catcher_context_impl.dart';
import 'package:revali_router/src/exception_catcher/exception_catcher_meta_impl.dart';
import 'package:revali_router/src/exceptions/close_web_socket_exception.dart';
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
import 'package:revali_router/src/payload/payload_impl.dart';
import 'package:revali_router/src/request/mutable_request_impl.dart';
import 'package:revali_router/src/request/request_context_impl.dart';
import 'package:revali_router/src/request/websocket_request_context_impl.dart';
import 'package:revali_router/src/response/canned_response.dart';
import 'package:revali_router/src/response/default_responses.dart';
import 'package:revali_router/src/response/mutable_response_impl.dart';
import 'package:revali_router/src/response/simple_response.dart';
import 'package:revali_router/src/response/web_socket_response.dart';
import 'package:revali_router/src/response_handler/default_response_handler.dart';
import 'package:revali_router/src/route/base_route.dart';
import 'package:revali_router/src/route/lifecycle_components_impl.dart';
import 'package:revali_router/src/route/route_match.dart';
import 'package:revali_router/src/route/web_socket_route.dart';
import 'package:revali_router/src/web_socket/web_socket_handler.dart';
import 'package:revali_router_core/response_handler/response_handler.dart';
import 'package:revali_router_core/revali_router_core.dart';
import 'package:stack_trace/stack_trace.dart';

part 'body_for_error.dart';
part 'execute.dart';
part 'find.dart';
part 'handle_web_socket.dart';
part 'mixins/context_mixin.dart';
part 'mixins/helper.dart';
part 'mixins/helper_mixin.dart';
part 'mixins/run.dart';
part 'mixins/run_mixin.dart';
part 'override_response.dart';
part 'router.g.dart';
part 'run_catchers.dart';
part 'run_guards.dart';
part 'run_interceptors.dart';
part 'run_middlewares.dart';
part 'run_options.dart';
part 'run_origin_check.dart';
part 'run_redirect.dart';

class Router extends Equatable {
  const Router({
    required this.routes,
    LifecycleComponents? globalComponents,
    Set<Reflect> reflects = const {},
    this.observers = const [],
    this.debug = false,
    this.defaultResponses = const DefaultResponses(),
    this.defaultResponseHandler = const DefaultResponseHandler(),
  })  : _reflects = reflects,
        _globalComponents = globalComponents;

  final List<Observer> observers;
  final List<BaseRoute> routes;
  final Set<Reflect> _reflects;
  final LifecycleComponents? _globalComponents;
  final bool debug;
  final DefaultResponses defaultResponses;
  final ResponseHandler defaultResponseHandler;

  /// Handles an HTTP request.
  ///
  /// Passes the request to the [handle] method.
  Future<ReadOnlyResponse> handleHttpRequest(HttpRequest request) async {
    final context = RequestContextImpl.fromRequest(request);
    return handle(context);
  }

  ReadOnlyResponse _debugResponse(
    ReadOnlyResponse response, {
    required Object error,
    required StackTrace stackTrace,
  }) {
    if (!debug) {
      if (response.statusCode >= 500) {
        return defaultResponses.internalServerError;
      }

      return response;
    }

    final ReadOnlyResponse(:body, :headers, :statusCode) = response;

    return SimpleResponse(
      statusCode,
      headers: headers.map((key, value) => MapEntry(key, value.join(','))),
      body: bodyForError(
        body,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }

  Future<ResponseHandler> responseHandler(RequestContext context) async {
    final match = Find(
      segments: context.segments,
      routes: routes,
      method: context.method,
    ).run();

    return match?.route.responseHandler ?? defaultResponseHandler;
  }

  Future<ReadOnlyResponse> handle(RequestContext context) async {
    final responseCompleter = Completer<ReadOnlyResponse>();

    HelperMixin helper;

    try {
      final request = MutableRequestImpl.fromRequest(context);

      for (final observer in observers) {
        observer.see(request, responseCompleter.future);
      }

      final segments = request.segments;

      final match = Find(
        segments: segments,
        routes: routes,
        method: request.method,
      ).run();

      if (match == null) {
        final response = _debugResponse(
          defaultResponses.notFound,
          error: RouteNotFoundException(
            method: request.method,
            path: segments.join('/'),
          ),
          stackTrace: StackTrace.current,
        );

        responseCompleter.complete(response);

        return response;
      }

      final RouteMatch(:route, :pathParameters) = match;
      request.pathParameters = pathParameters;

      helper = _createHelper(route, request);
    } catch (e, stackTrace) {
      final response = _debugResponse(
        defaultResponses.internalServerError,
        error: e,
        stackTrace: stackTrace,
      );

      responseCompleter.complete(response);

      return response;
    }

    // ignore: argument_type_not_assignable_to_error_handler
    final response = await _handle(helper).catchError(helper.run.catchers.call);

    responseCompleter.complete(response);

    return response;
  }

  Future<ReadOnlyResponse> _handle(HelperMixin helper) async {
    final HelperMixin(
      run: RunMixin(
        :options,
        :redirect,
        :originCheck,
        :execute,
        :catchers,
      ),
    ) = helper;

    if (options() case final response?) {
      return response;
    }

    if (redirect() case final response?) {
      return response;
    }

    if (originCheck() case final response?) {
      return response;
    }

    // ignore: argument_type_not_assignable_to_error_handler
    return execute().catchError(catchers.call);
  }

  HelperMixin _createHelper(BaseRoute route, MutableRequestImpl request) {
    return Helper(
      route: route,
      request: request,
      router: this,
    );
  }

  @override
  List<Object?> get props => _$props;
}
