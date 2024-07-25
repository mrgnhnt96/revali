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
    RouteMatch? _find({
      required Iterable<String> pathSegments,
      required Iterable<BaseRoute>? routes,
      required BaseRoute? parent,
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
}
