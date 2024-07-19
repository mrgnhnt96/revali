import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:revali_router/src/endpoint/endpoint_context_impl.dart';
import 'package:revali_router/src/exception_catcher/exception_catcher_context_impl.dart';
import 'package:revali_router/src/exception_catcher/exception_catcher_meta_impl.dart';
import 'package:revali_router/src/guard/guard_context_impl.dart';
import 'package:revali_router/src/guard/guard_meta_impl.dart';
import 'package:revali_router/src/interceptor/interceptor_context_impl.dart';
import 'package:revali_router/src/interceptor/interceptor_meta_impl.dart';
import 'package:revali_router/src/middleware/middleware_context_impl.dart';
import 'package:revali_router/src/request/mutable_request_impl.dart';
import 'package:revali_router/src/request/request_context_impl.dart';
import 'package:revali_router/src/request/websocket_request_context_impl.dart';
import 'package:revali_router/src/response/canned_response.dart';
import 'package:revali_router/src/response/mutable_response_impl.dart';
import 'package:revali_router/src/route/route.dart';
import 'package:revali_router/src/route/route_match.dart';
import 'package:revali_router/src/route/route_modifiers_impl.dart';
import 'package:revali_router_core/revali_router_core.dart';

part 'router.g.dart';

class Router extends Equatable {
  const Router._({
    required this.routes,
    required RouteModifiers? globalModifiers,
    required Set<Reflect> reflects,
    this.observers = const [],
  })  : _reflects = reflects,
        _globalModifiers = globalModifiers;

  Router({
    required List<Route> routes,
    RouteModifiers? globalModifiers,
    Set<Reflect> reflects = const {},
    List<Observer> observers = const [],
  }) : this._(
          routes: routes,
          globalModifiers: globalModifiers,
          reflects: reflects,
          observers: observers,
        );

  final List<Observer> observers;
  final List<Route> routes;
  final Set<Reflect> _reflects;
  final RouteModifiers? _globalModifiers;

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
    } catch (e) {
      final response = CannedResponse.internalServerError();

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
      return CannedResponse.notFound(
        body: 'Failed to find ${request.method}: ${segments.join('/')}',
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

    if (!isOriginAllowed(
      request,
      route,
      globalAllowedOrigins: globalModifiers.allowedOrigins?.origins,
      globalAllowedHeaders: globalModifiers.allowedHeaders?.headers,
    )) {
      return CannedResponse.forbidden();
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
    } catch (e) {
      if (e is! Exception) {
        return CannedResponse.internalServerError();
      }

      final catchers = [
        ...route.allCatchers,
        ...globalModifiers.catchers,
      ];

      for (final catcher in catchers) {
        if (!catcher.canCatch(e)) {
          continue;
        }

        final result = await catcher.catchException(
          e,
          ExceptionCatcherContextImpl(
            data: dataHandler,
            meta: ExceptionCatcherMetaImpl(
              direct: directMeta,
              inherited: inheritedMeta,
              route: route,
            ),
            request: request,
            response: response,
          ),
          const ExceptionCatcherAction(),
        );

        if (result.isHandled) {
          final (statusCode, headers, body) =
              result.asHandled.getResponseOverrides();

          return response
            .._overrideWith(
              statusCode: statusCode,
              backupCode: 500,
              headers: headers,
              body: body,
            );
        }
      }

      return CannedResponse.internalServerError();
    }
  }

  bool isOriginAllowed(
    MutableRequest request,
    Route route, {
    required Set<String>? globalAllowedOrigins,
    required Set<String>? globalAllowedHeaders,
  }) {
    final inheritGlobal = route.allowedOrigins?.inherit != false;
    final allAllowedOrigins = {
      if (inheritGlobal) ...?globalAllowedOrigins,
      ...route.allAllowedOrigins
    };

    var isAllowed = true;
    final origin = request.headers.origin;
    if (allAllowedOrigins case final allowedOrigins
        when allowedOrigins.isNotEmpty) {
      isAllowed = false;

      if (origin == null) {
        if (!allowedOrigins.contains('*')) {
          return false;
        }

        isAllowed = true;
      } else {
        for (final pattern in allowedOrigins) {
          if (pattern == '*' || pattern == origin) {
            isAllowed = true;
            break;
          }

          try {
            final regex = RegExp(pattern);
            if (regex.hasMatch(origin)) {
              isAllowed = true;
              break;
            }
          } catch (_) {
            // ignore the pattern if it is not a valid regex
          }
        }
      }
    }

    if (!isAllowed) {
      return false;
    }

    if (origin != null) {
      request.headers.set(HttpHeaders.accessControlAllowOriginHeader, origin);
    }

    request.headers
      ..set(HttpHeaders.accessControlAllowMethodsHeader,
          route.allowedMethods.join(', '))
      ..set(HttpHeaders.accessControlAllowCredentialsHeader, 'true')
      ..set(
          HttpHeaders.accessControlAllowHeadersHeader,
          {
            if (inheritGlobal) ...?globalAllowedHeaders,
            ...?route.allowedHeaders?.headers,
          }.join(', '));

    return true;
  }

  Future<ReadOnlyResponse> execute({
    required Route route,
    required RouteModifiers globalModifiers,
    required MutableRequest request,
    required MutableResponse response,
    required DataHandler dataHandler,
    required MetaHandler directMeta,
    required MetaHandler inheritedMeta,
    required ReflectHandler reflectHandler,
  }) async {
    final handler = route.handler;
    if (handler == null) {
      return CannedResponse.notFound();
    }

    final middlewares = [
      ...globalModifiers.middlewares,
      ...route.allMiddlewares,
    ];
    for (final middleware in middlewares) {
      final result = await middleware.use(
        MiddlewareContextImpl(
          request: request,
          response: response,
          data: dataHandler,
        ),
        const MiddlewareAction(),
      );

      if (result.isStop) {
        final (statusCode, headers, body) =
            result.asStop.getResponseOverrides();

        return response
          .._overrideWith(
            statusCode: statusCode,
            backupCode: 400,
            headers: headers,
            body: body,
          );
      }
    }

    final guards = [
      ...globalModifiers.guards,
      ...route.allGuards,
    ];
    for (final guard in guards) {
      final result = await guard.canActivate(
        GuardContextImpl(
          meta: GuardMetaImpl(
            direct: directMeta,
            inherited: inheritedMeta,
            route: route,
          ),
          response: response,
          request: request,
          data: dataHandler,
        ),
        const GuardAction(),
      );

      if (result.isNo) {
        final (statusCode, headers, body) = result.asNo.getResponseOverrides();

        return response
          .._overrideWith(
            statusCode: statusCode,
            backupCode: 403,
            headers: headers,
            body: body,
          );
      }
    }

    Future<void> run() async {
      final interceptors = [
        ...globalModifiers.interceptors,
        ...route.allInterceptors,
      ];
      for (final interceptor in interceptors) {
        await interceptor.pre(
          InterceptorContextImpl(
            meta: InterceptorMetaImpl(
              direct: directMeta,
              inherited: inheritedMeta,
            ),
            reflect: reflectHandler,
            request: request,
            response: response,
            data: dataHandler,
          ),
        );
      }

      await handler.call(
        EndpointContextImpl(
          meta: directMeta,
          reflect: reflectHandler,
          request: request,
          data: dataHandler,
          response: response,
        ),
      );

      for (final interceptor in interceptors) {
        await interceptor.post(
          InterceptorContextImpl(
            meta: InterceptorMetaImpl(
              direct: directMeta,
              inherited: inheritedMeta,
            ),
            reflect: reflectHandler,
            request: request,
            response: response,
            data: dataHandler,
          ),
        );
      }
    }

    if (route.isWebSocket) {
      WebSocket webSocket;
      MutableWebSocketRequest wsRequest;
      try {
        webSocket = await request.upgradeToWebSocket();
        wsRequest = MutableWebSocketRequestImpl.fromRequest(request);
      } catch (e) {
        return CannedResponse.internalServerError();
      }

      final sub = webSocket.listen((event) async {
        response.body = null;
        await wsRequest.overrideBody(event);

        await run();

        final body = response.body;
        if (body.isNull) {
          return;
        }

        webSocket.add(body.read());
      });

      await sub.asFuture();

      return CannedResponse.webSocket();
    }

    await run();
    return response;
  }

  RouteMatch? find({
    required Iterable<String> segments,
    required Iterable<Route>? routes,
    required String method,
  }) {
    RouteMatch? _find({
      required Iterable<String> pathSegments,
      required Iterable<Route>? routes,
      required Route? parent,
      required String method,
      required Map<String, String> pathParameters,
    }) {
      if (routes == null || routes.isEmpty) {
        if (parent == null) {
          return null;
        }

        final parts = pathSegments.take(parent.segments.length);
        final _remainingPathSegments = pathSegments.skip(parts.length).toList();

        if (_remainingPathSegments.isEmpty &&
            (parent.canInvoke &&
                (parent.method == method ||
                    parent.method == 'GET' && method == 'HEAD'))) {
          return RouteMatch(
            route: parent,
            pathParameters: pathParameters,
          );
        }

        return null;
      }

      final sorted = routes.toList()
        // dynamic goes last
        ..sort((a, b) => a.isDynamic ? 1 : 0);

      for (final route in sorted) {
        if (pathSegments.length < route.segments.length) {
          continue;
        }

        final _pathSegments = pathSegments.take(route.segments.length);

        if (route.isDynamic) {
          final _segments = [
            for (final segment in route.segments.take(_pathSegments.length))
              if (segment.startsWith(':')) r'(.+)' else segment
          ];

          final pattern = RegExp('^${_segments.join(r'\/')}\$');

          if (pattern.hasMatch(_pathSegments.join('/')) &&
              route.method == method) {
            for (var i = 0; i < route.segments.length; i++) {
              final segment = route.segments[i];
              if (segment.startsWith(':')) {
                pathParameters[segment.substring(1)] =
                    _pathSegments.elementAt(i);
              }
            }

            final poss = _find(
              pathSegments: pathSegments.skip(_pathSegments.length),
              routes: route.routes,
              parent: route,
              method: method,
              pathParameters: pathParameters,
            );

            if (poss != null) {
              return poss;
            }
          }
        } else if (_pathSegments.join('/') == route.path) {
          final _segments = pathSegments.skip(_pathSegments.length).toList();

          if (_segments.isEmpty) {
            if (route.canInvoke) {
              if (route.method == method ||
                  (route.method == 'GET' && method == 'HEAD') ||
                  method == 'OPTIONS') {
                return RouteMatch(
                  route: route,
                  pathParameters: pathParameters,
                );
              } else {
                continue;
              }
            } else {
              // If the route cannot be invoked, we need to add an empty segment
              // to the segments list to continue the search for the nested
              // route that can be invoked and is empty
              _segments.add('');
            }
          }

          return _find(
            pathSegments: _segments,
            routes: route.routes,
            parent: route,
            method: method,
            pathParameters: pathParameters,
          );
        }
      }

      return null;
    }

    return _find(
      pathSegments: segments,
      routes: routes,
      parent: null,
      method: method,
      pathParameters: {},
    );
  }

  @override
  List<Object?> get props => _$props;
}

extension _MutableResponseX on MutableResponse {
  void _overrideWith({
    required int? statusCode,
    required int backupCode,
    required Map<String, String>? headers,
    required Object? body,
  }) {
    final _body = switch (body) {
      BodyData() => body,
      _ => BaseBodyData.from(body),
    };

    if (!_body.isNull) {
      this.body = _body;
    }

    this.statusCode = statusCode ?? backupCode;

    if (headers != null) {
      this.headers.addAll(headers);
    }
  }
}
