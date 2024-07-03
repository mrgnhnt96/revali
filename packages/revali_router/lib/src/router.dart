import 'package:equatable/equatable.dart';
import 'package:revali_router/src/endpoint/endpoint_context_impl.dart';
import 'package:revali_router/src/guard/guard_action.dart';
import 'package:revali_router/src/guard/guard_context.dart';
import 'package:revali_router/src/guard/guard_meta.dart';
import 'package:revali_router/src/interceptor/interceptor_action.dart';
import 'package:revali_router/src/interceptor/interceptor_context.dart';
import 'package:revali_router/src/interceptor/interceptor_meta.dart';
import 'package:revali_router/src/middleware/middleware_action.dart';
import 'package:revali_router/src/middleware/middleware_context.dart';
import 'package:revali_router/src/request/request_context.dart';
import 'package:revali_router/src/route.dart';
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
    final context = RequestContext.from(this.context);
    final segments = context.segments;

    final route = find(
      segments: segments,
      routes: routes,
      method: context.method,
    );

    if (route == null) {
      return Response.notFound(null);
    }

    final handler = route.handler;
    if (handler == null) {
      return Response.notFound(null);
    }

    final middlewareAction = MiddlewareAction();

    final directMeta = route.getMeta();
    final inheritedMeta = route.getMeta(inherit: true);
    final middlewareContext = MiddlewareContext.from(context);

    for (final middleware in route.allMiddlewares) {
      final result = await middleware.use(
        middlewareContext,
        middlewareAction,
      );

      if (result.isCancel) {
        final context = middlewareContext.getContext();

        return context.getErrorResponse();
      }
    }

    final guardContext = GuardContext.from(
      context,
      meta: GuardMeta(
        direct: directMeta,
        inherited: inheritedMeta,
        route: route,
      ),
    );

    final guardAction = GuardAction();
    for (final guard in route.allGuards) {
      final result = await guard.canNavigate(guardContext, guardAction);

      if (result.isNo) {
        final context = guardContext.getContext();

        return context.getErrorResponse();
      }
    }

    final interceptorAction = InterceptorAction();
    var interceptorContext = InterceptorContext.from(
      context,
      meta: InterceptorMeta(
        direct: directMeta,
        inherited: inheritedMeta,
      ),
    );

    for (final interceptor in route.allInterceptors) {
      interceptor.pre(
        interceptorContext,
        interceptorAction,
      );
    }

    final endpointContext = EndpointContextImpl.from(context);

    await handler.call(endpointContext);

    interceptorContext = InterceptorContext.from(
      context,
      meta: InterceptorMeta(
        direct: directMeta,
        inherited: inheritedMeta,
      ),
    );

    for (final interceptor in route.allInterceptors) {
      interceptor.post(
        interceptorContext,
        InterceptorMeta(
          direct: directMeta,
          inherited: inheritedMeta,
        ),
      );
    }

    final responseContext = interceptorContext.getContext();

    return responseContext.getSuccessResponse();
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
