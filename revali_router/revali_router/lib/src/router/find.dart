part of 'router.dart';

class Find {
  const Find({
    required this.segments,
    required this.routes,
    required this.method,
  });

  final List<String> segments;
  final List<BaseRoute>? routes;
  final String method;

  RouteMatch? run() {
    RouteMatch? find({
      required List<String> pathSegments,
      required List<BaseRoute>? routes,
      required BaseRoute? parent,
      required String method,
      required Map<String, String> pathParameters,
    }) {
      if (routes == null || routes.isEmpty) {
        if (parent == null) {
          return null;
        }

        final parts = pathSegments.take(parent.segments.length);
        final remainingPathSegments = pathSegments.skip(parts.length).toList();

        if (remainingPathSegments.isEmpty &&
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
          final routeIsEmpty =
              route.segments.where((e) => e.isNotEmpty).isEmpty;
          if (pathSegments.isEmpty && routeIsEmpty) {
            // allow empty route to match when path is empty
          } else {
            continue;
          }
        }

        final possibleSameSegments = pathSegments.take(route.segments.length);
        final hasMoreSegments = pathSegments.length > route.segments.length;

        BaseRoute? proxy;
        if (!route.canInvoke) {
          final segmentsToSkip = switch (route) {
            BaseRoute(path: '') => max(possibleSameSegments.length - 1, 0),
            _ => possibleSameSegments.length,
          };
          final poss = find(
            pathSegments: pathSegments.skip(segmentsToSkip).toList(),
            routes: route.routes,
            parent: route,
            method: method,
            pathParameters: pathParameters,
          );

          proxy = poss?.route;
        }

        if (route.isDynamic) {
          final segments = [
            for (final segment
                in route.segments.take(possibleSameSegments.length))
              if (segment.startsWith(':')) '(.+)' else segment,
          ];

          final pattern = RegExp('^${segments.join(r'\/')}\$');

          final methodsMatch = route.method == method;
          final almostMatches =
              (route.method == null || route.method != method) &&
                  hasMoreSegments;
          final patternMatches =
              pattern.hasMatch(possibleSameSegments.join('/'));

          if (patternMatches &&
              (methodsMatch || almostMatches || proxy != null)) {
            for (var i = 0; i < route.segments.length; i++) {
              final segment = route.segments[i];
              if (segment.startsWith(':')) {
                pathParameters[segment.substring(1)] =
                    possibleSameSegments.elementAt(i);
              }
            }

            if (proxy != null) {
              return RouteMatch(
                route: proxy,
                pathParameters: pathParameters,
              );
            }

            final poss = find(
              pathSegments:
                  pathSegments.skip(possibleSameSegments.length).toList(),
              routes: route.routes,
              parent: route,
              method: method,
              pathParameters: pathParameters,
            );

            if (poss != null) {
              return poss;
            }
          }
        } else if (possibleSameSegments.join('/') case final path
            when path == route.path ||
                (route.path.isEmpty && path == proxy?.path)) {
          final checkRoute = switch (route.path) {
            _ when route.path == path => route,
            '' => proxy,
            _ => null,
          };

          final segments =
              pathSegments.skip(possibleSameSegments.length).toList();

          if (segments.isEmpty) {
            if (checkRoute case final route? when route.canInvoke) {
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
              segments.add('');
            }
          }

          return find(
            pathSegments: segments,
            routes: checkRoute?.routes,
            parent: route,
            method: method,
            pathParameters: pathParameters,
          );
        }
      }

      return null;
    }

    return find(
      pathSegments: segments,
      routes: routes,
      parent: null,
      method: method,
      pathParameters: {},
    );
  }
}
