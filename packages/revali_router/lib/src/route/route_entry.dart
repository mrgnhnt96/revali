import 'package:revali_router/src/route/route.dart';

class RouteEntry {
  RouteEntry(Route route)
      : path = route.path,
        method = route.method,
        parent = route.parent;

  final String path;
  final RouteEntry? parent;
  final String? method;
}
