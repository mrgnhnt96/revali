abstract class RouteEntry {
  const RouteEntry();

  String get path;
  RouteEntry? get parent;
  String? get method;
  String get fullPath;
}
