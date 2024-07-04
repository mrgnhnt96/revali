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

    final route = find(
      segments: segments,
      routes: routes,
      method: request.method,
    );

    if (route == null) {
      return Response.notFound(null);
    }

    final catchers = route.allCatchers;
    final response = MutableResponseContextImpl();
    final directMeta = route.getMeta();
    final inheritedMeta = route.getMeta(inherit: true);
    final dataHandler = DataHandler();

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

  Route? find({
    required Iterable<String> segments,
    required Iterable<Route>? routes,
    required String method,
  }) {
    if (routes == null) {
      return null;
    }

    for (final route in routes) {
      if (segments.length < route.segments.length) {
        continue;
      }

      final parts = segments.take(route.segments.length);

      if (route.isDynamic) {
        final _segments = [
          for (final segment in route.segments.take(parts.length))
            if (segment.startsWith(':')) r'.+' else segment
        ];

        final pattern = RegExp('^${_segments.join(r'\/')}\$');

        if (pattern.hasMatch(parts.join('/')) && route.method == method) {
          return route;
        }
      } else if (parts.join('/') == route.path) {
        final _segments = segments.skip(parts.length).toList();

        if (_segments.isEmpty) {
          if (route.canInvoke) {
            if (route.method == method) {
              return route;
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

        return find(
          segments: _segments,
          routes: route.routes,
          method: method,
        );
      }
    }

    return null;
  }

  @override
  List<Object?> get props => _$props;
}
