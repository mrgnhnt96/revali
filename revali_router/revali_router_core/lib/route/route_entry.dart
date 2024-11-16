import 'package:revali_router_core/response_handler/response_handler.dart';

abstract class RouteEntry {
  const RouteEntry();

  String get path;
  RouteEntry? get parent;
  String? get method;
  String get fullPath;
  ResponseHandler? get responseHandler;
}
