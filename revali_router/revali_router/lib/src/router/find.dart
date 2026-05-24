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
    }) {
      if (routes == null || routes.isEmpty) {
        if (parent == null) {
          return null;
        }

        if (pathSegments.isEmpty &&
            (parent.canInvoke &&
                (parent.method == method ||
                    parent.method == 'GET' && method == 'HEAD'))) {
          return RouteMatch(parent);
        }

        return null;
      }

      final sorted = routes.toList()
        ..sort((a, b) {
          int order(BaseRoute route) {
            if (route.hasWildcard) {
              return 1000;
            }
            if (route.isDynamic) {
              return 100;
            }

            // Prefer more specific static routes first.
            return 100 - route.segments.length;
          }

          final orderCompare = order(a).compareTo(order(b));
          if (orderCompare != 0) {
            return orderCompare;
          }

          return a.path.compareTo(b.path);
        });

      for (final route in sorted) {
        final wildcardIndex =
            route.segments.indexWhere((segment) => segment.startsWith('*'));

        if (wildcardIndex != -1) {
          if (pathSegments.length < wildcardIndex) {
            continue;
          }

          final prefixRouteSegments =
              route.segments.take(wildcardIndex).toList();
          final prefixPathSegments = pathSegments.take(wildcardIndex).toList();

          if (!_prefixMatches(prefixRouteSegments, prefixPathSegments)) {
            continue;
          }

          if (pathSegments.length == wildcardIndex &&
              _hasExactStaticSibling(
                routes: sorted,
                wildcardRoute: route,
                exactPath: prefixPathSegments.join('/'),
                method: method,
              )) {
            continue;
          }

          final hasMoreSegments = pathSegments.length > wildcardIndex;

          BaseRoute? proxy;
          if (!route.canInvoke) {
            final segmentsToSkip = switch (route) {
              BaseRoute(path: '') => max(prefixPathSegments.length - 1, 0),
              _ => prefixPathSegments.length,
            };
            final poss = find(
              pathSegments: pathSegments.skip(segmentsToSkip).toList(),
              routes: route.routes,
              parent: route,
              method: method,
            );

            proxy = poss?.route;
          }

          final methodsMatch = route.method == method;
          final almostMatches =
              (route.method == null || route.method != method) &&
                  hasMoreSegments;
          final optionsMatch = method == 'OPTIONS' && route.canInvoke;

          if (methodsMatch || almostMatches || proxy != null || optionsMatch) {
            if (proxy != null) {
              return RouteMatch(proxy);
            }

            if (route.canInvoke) {
              if (methodsMatch ||
                  (route.method == 'GET' && method == 'HEAD') ||
                  method == 'OPTIONS') {
                return RouteMatch(route);
              }
            }
          }

          continue;
        }

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
          final optionsMatch = method == 'OPTIONS' && route.canInvoke;
          final patternMatches =
              pattern.hasMatch(possibleSameSegments.join('/'));

          if (patternMatches &&
              (methodsMatch ||
                  almostMatches ||
                  proxy != null ||
                  optionsMatch)) {
            if (proxy != null) {
              return RouteMatch(proxy);
            }

            final remainingSegments =
                pathSegments.skip(possibleSameSegments.length).toList();
            if (remainingSegments.isEmpty && route.canInvoke) {
              if (methodsMatch ||
                  (route.method == 'GET' && method == 'HEAD') ||
                  method == 'OPTIONS') {
                return RouteMatch(route);
              }
            }

            final poss = find(
              pathSegments: remainingSegments,
              routes: route.routes,
              parent: route,
              method: method,
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
                return RouteMatch(route);
              } else {
                continue;
              }
            }
            // For OPTIONS, return prefix routes (no handler)
            // so CORS can respond
            // with aggregated allowed methods from descendants
            if (checkRoute case final prefixRoute?
                when method == 'OPTIONS' &&
                    (prefixRoute.routes?.isNotEmpty ?? false)) {
              return RouteMatch(prefixRoute);
            }
            // If the route cannot be invoked, we need to add an empty segment
            // to the segments list to continue the search for the nested
            // route that can be invoked and is empty
            segments.add('');
          }

          final poss = find(
            pathSegments: segments,
            routes: checkRoute?.routes,
            parent: route,
            method: method,
          );
          if (poss != null) return poss;
        }
      }

      return null;
    }

    final result = find(
      pathSegments: segments,
      routes: routes,
      parent: null,
      method: method,
    );

    if (result == null) {
      return null;
    }

    return result.resolvePathParameters(segments);
  }

  static bool _prefixMatches(
    List<String> routeSegments,
    List<String> pathSegments,
  ) {
    if (routeSegments.length != pathSegments.length) {
      return false;
    }

    for (var i = 0; i < routeSegments.length; i++) {
      final routeSegment = routeSegments[i];
      final pathSegment = pathSegments[i];

      if (routeSegment.startsWith(':')) {
        continue;
      }

      if (routeSegment != pathSegment) {
        return false;
      }
    }

    return true;
  }

  bool _hasExactStaticSibling({
    required List<BaseRoute> routes,
    required BaseRoute wildcardRoute,
    required String exactPath,
    required String method,
  }) {
    for (final sibling in routes) {
      if (identical(sibling, wildcardRoute)) {
        continue;
      }

      if (sibling.hasWildcard || sibling.isDynamic) {
        continue;
      }

      if (sibling.path != exactPath || !sibling.canInvoke) {
        continue;
      }

      if (sibling.method == method ||
          sibling.method == 'GET' && method == 'HEAD') {
        return true;
      }
    }

    return false;
  }
}
