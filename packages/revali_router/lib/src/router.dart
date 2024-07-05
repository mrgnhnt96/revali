import 'package:equatable/equatable.dart';
import 'package:revali_router/src/data/data_handler.dart';
import 'package:revali_router/src/endpoint/endpoint_context_impl.dart';
import 'package:revali_router/src/exception_catcher/exception_catcher_action.dart';
import 'package:revali_router/src/exception_catcher/exception_catcher_context_impl.dart';
import 'package:revali_router/src/exception_catcher/exception_catcher_meta_impl.dart';
import 'package:revali_router/src/guard/guard_action.dart';
import 'package:revali_router/src/guard/guard_context_impl.dart';
import 'package:revali_router/src/guard/guard_meta.dart';
import 'package:revali_router/src/interceptor/interceptor_context_impl.dart';
import 'package:revali_router/src/interceptor/interceptor_meta.dart';
import 'package:revali_router/src/meta/meta_handler.dart';
import 'package:revali_router/src/middleware/middleware_action.dart';
import 'package:revali_router/src/middleware/middleware_context_impl.dart';
import 'package:revali_router/src/request/mutable_request_context_impl.dart';
import 'package:revali_router/src/request/request_context.dart';
import 'package:revali_router/src/response/mutable_response_context_impl.dart';
import 'package:revali_router/src/route/route.dart';
import 'package:revali_router/src/route/route_match.dart';
import 'package:shelf/shelf.dart';

part 'router.g.dart';

class Router extends Equatable {
  const Router(
    this.context, {
    required this.routes,
  });

  final RequestContext context;
  final List<Route> routes;

  Future<Response> handle() async {
    final request = MutableRequestContextImpl.from(this.context);
    final segments = request.segments;

    final match = find(
      segments: segments,
      routes: routes,
      method: request.method,
    );

    if (match == null) {
      return Response.notFound(null);
    }

    final RouteMatch(:route, :pathParameters) = match;
    request.setPathParameters(pathParameters);

    final catchers = route.allCatchers;
    final response = MutableResponseContextImpl();
    final directMeta = route.getMeta();
    final inheritedMeta = route.getMeta(inherit: true);
    final dataHandler = DataHandler();

    for (final data in route.allData) {
      data.apply(dataHandler);
    }

    try {
      final result = await execute(
        route: route,
        request: request,
        response: response,
        dataHandler: dataHandler,
        directMeta: directMeta,
        inheritedMeta: inheritedMeta,
      );

      return result;
    } catch (e) {
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

          return response.overrideWith(
            statusCode: statusCode,
            defaultStatusCode: 500,
            headers: headers,
            body: body,
          );
        }
      }

      return Response.internalServerError();
    }
  }

  Future<Response> execute({
    required Route route,
    required MutableRequestContextImpl request,
    required MutableResponseContextImpl response,
    required DataHandler dataHandler,
    required MetaHandler directMeta,
    required MetaHandler inheritedMeta,
  }) async {
    final handler = route.handler;
    if (handler == null) {
      return Response.notFound(null);
    }

    for (final middleware in route.allMiddlewares) {
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

        return response.overrideWith(
          statusCode: statusCode,
          defaultStatusCode: 400,
          headers: headers,
          body: body,
        );
      }
    }

    for (final guard in route.allGuards) {
      final result = await guard.canActivate(
        GuardContextImpl(
          meta: GuardMeta(
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
        return response.overrideWith(
          statusCode: statusCode,
          defaultStatusCode: 403,
          headers: headers,
          body: body,
        );
      }
    }

    for (final interceptor in route.allInterceptors) {
      await interceptor.pre(
        InterceptorContextImpl(
          meta: InterceptorMeta(
            direct: directMeta,
            inherited: inheritedMeta,
          ),
          request: request,
          response: response,
          data: dataHandler,
        ),
      );
    }

    await handler.call(
      EndpointContextImpl(
        request: request,
        data: dataHandler,
        response: response,
      ),
    );

    for (final interceptor in route.allInterceptors) {
      await interceptor.post(
        InterceptorContextImpl(
          meta: InterceptorMeta(
            direct: directMeta,
            inherited: inheritedMeta,
          ),
          request: request,
          response: response,
          data: dataHandler,
        ),
      );
    }

    return response.get();
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
      if (routes == null) {
        if (parent == null) {
          return null;
        }

        final parts = pathSegments.take(parent.segments.length);
        final _remainingPathSegments = pathSegments.skip(parts.length).toList();

        if (_remainingPathSegments.isEmpty &&
            parent.canInvoke &&
            parent.method == method) {
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
              if (route.method == method) {
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
