import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:http_parser/http_parser.dart';
import 'package:meta/meta.dart';
import 'package:revali_annotations/revali_annotations.dart'
    hide Body, LifecycleComponents, WebSocket;
import 'package:revali_core/revali_core.dart';
import 'package:revali_router/src/body/body_impl.dart';
import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:revali_router/src/context/context_impl.dart';
import 'package:revali_router/src/data/data_impl.dart';
import 'package:revali_router/src/exceptions/close_web_socket_exception.dart';
import 'package:revali_router/src/exceptions/guard_stop_exception.dart';
import 'package:revali_router/src/exceptions/invalid_handler_result_exception.dart';
import 'package:revali_router/src/exceptions/middleware_stop_exception.dart';
import 'package:revali_router/src/exceptions/missing_argument_exception.dart';
import 'package:revali_router/src/exceptions/missing_handler_exception.dart';
import 'package:revali_router/src/exceptions/route_not_found_exception.dart';
import 'package:revali_router/src/meta/meta_scope_impl.dart';
import 'package:revali_router/src/payload/payload_impl.dart';
import 'package:revali_router/src/request/request_context_impl.dart';
import 'package:revali_router/src/request/request_impl.dart';
import 'package:revali_router/src/request/web_socket_request_context_impl.dart';
import 'package:revali_router/src/response/canned_response.dart';
import 'package:revali_router/src/response/default_responses.dart';
import 'package:revali_router/src/response/response_impl.dart';
import 'package:revali_router/src/response/simple_response.dart';
import 'package:revali_router/src/response/web_socket_response.dart';
import 'package:revali_router/src/response_handler/default_response_handler.dart';
import 'package:revali_router/src/route/base_route.dart';
import 'package:revali_router/src/route/lifecycle_components_impl.dart';
import 'package:revali_router/src/route/route_match.dart';
import 'package:revali_router/src/route/web_socket_route.dart';
import 'package:revali_router/src/router/request_trace.dart';
import 'package:revali_router/src/web_socket/async_web_socket_sender_impl.dart';
import 'package:revali_router/src/web_socket/web_socket_close_impl.dart';
import 'package:revali_router/src/web_socket/web_socket_context_impl.dart';
import 'package:revali_router/src/web_socket/web_socket_handler.dart';
import 'package:revali_router/utils/sequential_executor.dart';
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
part 'run_wrappers.dart';

class Router extends Equatable {
  Router({
    required this.routes,
    LifecycleComponents? globalComponents,
    Set<ReflectData> reflects = const {},
    this.observers = const [],
    this.debug = false,
    this.inspect = false,
    this.inspectLogPath = '',
    this.defaultResponses = const DefaultResponses(),
    this.trustedProxy = const TrustedProxy(),
    this.compression = const CompressionSettings(),
    this.di,
  })  : _reflects = reflects,
        _globalComponents = globalComponents {
    _prepareRoutes(routes);
  }

  /// Gzip settings for responses this router sends through its default
  /// response handler. A route or global component supplying its own handler
  /// is responsible for its own compression.
  final CompressionSettings compression;

  /// The application container every request scopes from.
  ///
  /// When set, each request runs with its own [RequestScopedDI] installed, so
  /// dependencies registered with `registerRequestScoped` are built once per
  /// request and disposed when it ends. Null leaves requests unscoped, which
  /// is how a [Router] constructed directly (in tests, say) behaves.
  final DI? di;

  final List<Observer> observers;
  final List<BaseRoute> routes;
  final Set<ReflectData> _reflects;
  final LifecycleComponents? _globalComponents;
  final bool debug;

  /// When true (or [debug] is true), retain recent [RequestTrace]s in memory.
  final bool inspect;

  /// When non-empty, append JSONL traces for MCP / tooling.
  final String inspectLogPath;
  final DefaultResponses defaultResponses;
  final TrustedProxy trustedProxy;

  final List<void Function()> _cleanUp = [];

  /// Cleanups registered by requests that haven't run yet (e.g. still
  /// in-flight, or a long-lived connection that hasn't closed). Exposed for
  /// tests to catch this list growing unbounded; not meant for app logic.
  @visibleForTesting
  int get pendingCleanUpCount => _cleanUp.length;

  /// Ring buffer of recent requests (newest last). Capped at 50.
  final List<RequestTrace> debugRequestLog = [];
  static const int _maxRequestTraces = 50;

  /// Exact `METHOD path` → invokable static route (no `:param` / `*`).
  final Map<String, BaseRoute> _staticRoutes = {};

  void _prepareRoutes(List<BaseRoute> level) {
    for (final route in level) {
      if (route.routes case final children?) {
        _prepareRoutes(children);
      }
      if (route.isStatic && route.canInvoke) {
        final path = route.fullSegments.join('/');
        final method = route.method!;
        _staticRoutes['$method $path'] = route;
        if (method == 'GET') {
          _staticRoutes['HEAD $path'] = route;
        }
      }
    }
  }

  RouteMatch? _findMatch(List<String> segments, String method) {
    final staticKey = '$method ${segments.join('/')}';
    if (_staticRoutes[staticKey] case final route?) {
      return RouteMatch(route);
    }

    return Find(
      segments: segments,
      routes: routes,
      method: method,
    ).run();
  }

  /// End-to-end HTTP serve path used by `handleRouterRequests`.
  ///
  /// Performs a **single** route Find, then writes the response — unlike the
  /// older `handleRequests` + [responseHandler] + [handle] split which Finds
  /// twice per request.
  Future<void> handleRequest(HttpRequest httpRequest) async {
    // The scope covers writing the response too, not just the pipeline, so a
    // streaming body can still resolve what it was built with. Disposal is
    // awaited here, which also means a graceful shutdown drains it.
    if (di case final parent?) {
      return RequestScopedDI(parent: parent).run(
        () => _handleRequest(httpRequest),
      );
    }

    return _handleRequest(httpRequest);
  }

  Future<void> _handleRequest(HttpRequest httpRequest) async {
    final started = DateTime.now();
    final context = RequestContextImpl.fromRequest(
      httpRequest,
      trustedProxy: trustedProxy,
    );

    final (response, responseHandler) = await _handleWithHandler(context);
    _recordTrace(context, response, started);
    await responseHandler.handle(response, context, httpRequest.response);
  }

  /// Handles an HTTP request.
  ///
  /// Passes the request to the [handle] method.
  Future<Response> handleHttpRequest(HttpRequest request) async {
    final context = RequestContextImpl.fromRequest(
      request,
      trustedProxy: trustedProxy,
    );
    return await handle(context);
  }

  Response _debugResponse(
    Response response, {
    required Object error,
    required StackTrace stackTrace,
  }) {
    if (!debug) {
      if (response.statusCode >= 500) {
        return defaultResponses.internalServerError;
      }

      return response;
    }

    final Response(:body, :headers, :statusCode) = response;

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
    final match = _findMatch(context.segments.toList(), context.method);

    return _responseHandlerFor(match?.route);
  }

  ResponseHandler _responseHandlerFor(BaseRoute? route) {
    return route?.responseHandler ??
        _globalComponents?.responseHandler ??
        _defaultResponseHandler;
  }

  late final _defaultResponseHandler = DefaultResponseHandler(
    compression: compression,
  );

  void close() {
    // Iterate a copy: each entry removes itself from [_cleanUp] as it runs,
    // which is a concurrent modification if we walk the live list. Only
    // reachable when close() happens with requests still registered -- e.g. a
    // graceful shutdown -- so it stayed hidden while close() only ever ran
    // after everything had already drained.
    for (final cleanUp in [..._cleanUp]) {
      try {
        cleanUp();
      } catch (_) {}
    }
  }

  Future<Response> handle(RequestContext context) async {
    if (di case final parent?) {
      final scope = RequestScopedDI(parent: parent);

      // The caller writes the response after this returns, so disposal has to
      // wait for the context to close rather than for this future. Not
      // awaited, because [RequestContext.close] is synchronous -- errors are
      // handled inside dispose().
      context.addCleanUp(() => unawaited(scope.dispose()));

      return runZoned(
        () => _handle0(context),
        zoneValues: {RequestScopedDI.zoneKey: scope},
      );
    }

    return _handle0(context);
  }

  Future<Response> _handle0(RequestContext context) async {
    final started = DateTime.now();
    final (response, _) = await _handleWithHandler(context);
    _recordTrace(context, response, started);
    return response;
  }

  Future<(Response, ResponseHandler)> _handleWithHandler(
    RequestContext context,
  ) async {
    final responseCompleter = Completer<Response>();

    HelperMixin helper;
    late final ResponseHandler responseHandler;

    try {
      final request = RequestImpl.fromRequest(context);

      final segments = request.segments;

      final match = _findMatch(segments, request.method);

      responseHandler = _responseHandlerFor(match?.route);

      if (match == null) {
        final response = _debugResponse(
          defaultResponses.notFound,
          error: RouteNotFoundException(
            method: request.method,
            path: segments.join('/'),
          ),
          stackTrace: StackTrace.current,
        );

        _notifyObservers(request, responseCompleter.future);

        responseCompleter.complete(response);

        return (response, responseHandler);
      }

      final RouteMatch(:route, :pathParameters) = match;
      final wildcardKeys = {
        for (final segment in route.fullSegments)
          if (segment.startsWith('*'))
            segment == '*' ? '*' : segment.substring(1),
      };

      request
        ..pathParameters = {
          for (final entry in pathParameters.entries)
            entry.key:
                entry.value.length == 1 && !wildcardKeys.contains(entry.key)
                    ? entry.value.first
                    : entry.value.join('/'),
        }
        ..wildcardParameters = {
          for (final key in wildcardKeys)
            if (pathParameters.containsKey(key))
              key: List<String>.from(pathParameters[key]!),
        };

      helper = _createHelper(
        route,
        request,
        observerResponseFuture: responseCompleter.future,
      );
    } catch (e, stackTrace) {
      responseHandler = _responseHandlerFor(null);
      final response = _debugResponse(
        defaultResponses.internalServerError,
        error: e,
        stackTrace: stackTrace,
      );

      _notifyObservers(
        RequestImpl.fromRequest(context),
        responseCompleter.future,
      );

      responseCompleter.complete(response);

      return (response, responseHandler);
    }

    final cleanUp = helper.data.get<CleanUp>();
    if (cleanUp is CleanUpImpl) {
      // Registered on the router too, so a connection that never gets to
      // close naturally (e.g. abandoned mid-flight) still runs its cleanup
      // when the router itself closes. Self-removing so the common case --
      // the request's own `context.close()` already ran it -- doesn't leave
      // a dead entry behind; otherwise this list grows by one per request
      // for the life of the process and never shrinks.
      void runCleanUp() {
        _cleanUp.remove(runCleanUp);
        cleanUp.clean();
      }

      context.addCleanUp(runCleanUp);
      _cleanUp.add(runCleanUp);
    }

    // ignore: argument_type_not_assignable_to_error_handler
    final response = await _handle(helper).catchError(helper.run.catchers.call);

    responseCompleter.complete(response);

    return (response, responseHandler);
  }

  Future<Response> _handle(HelperMixin helper) async {
    final HelperMixin(
      run: RunMixin(
        :options,
        :redirect,
        :originCheck,
        :execute,
        :catchers,
      ),
    ) = helper;

    if (originCheck() case final response?) {
      return response;
    }

    if (options() case final response?) {
      return response;
    }

    if (redirect() case final response?) {
      return response;
    }

    // ignore: argument_type_not_assignable_to_error_handler
    return await execute.run().catchError(catchers.call);
  }

  HelperMixin _createHelper(
    BaseRoute route,
    RequestImpl request, {
    required Future<Response> observerResponseFuture,
  }) {
    return Helper(
      route: route,
      request: request,
      router: this,
      observers: observers,
      observerResponseFuture: observerResponseFuture,
    );
  }

  void _notifyObservers(FullRequest request, Future<Response> response) {
    if (observers.isEmpty) {
      return;
    }
    for (final observer in observers) {
      observer.see(request, response).ignore();
    }
  }

  void _recordTrace(
    RequestContext context,
    Response response,
    DateTime started,
  ) {
    if (!debug && !inspect) {
      return;
    }

    final trace = RequestTrace(
      method: context.method,
      path: context.segments.join('/'),
      statusCode: response.statusCode,
      durationMs: DateTime.now().difference(started).inMilliseconds,
      error: response.statusCode >= 400 ? '${response.body.data}' : null,
      at: started,
    );

    debugRequestLog.add(trace);
    while (debugRequestLog.length > _maxRequestTraces) {
      debugRequestLog.removeAt(0);
    }

    final logPath = inspectLogPath;
    if (logPath.isNotEmpty) {
      try {
        final file = File(logPath);
        file.parent.createSync(recursive: true);
        file.writeAsStringSync(
          '${jsonEncode(trace.toJson())}\n',
          mode: FileMode.append,
        );
      } catch (_) {}
    }
  }

  @override
  List<Object?> get props => _$props;
}
