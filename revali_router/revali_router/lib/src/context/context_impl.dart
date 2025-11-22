import 'package:revali_router_core/revali_router_core.dart';

class ContextImpl implements Context {
  const ContextImpl({
    required this.data,
    required this.meta,
    required this.request,
    required this.response,
    required this.reflect,
    required this.route,
  });

  @override
  final Data data;

  @override
  final MetaScope meta;

  @override
  final RouteEntry route;

  @override
  final Request request;

  @override
  final Response response;

  @override
  final Reflect reflect;
}
