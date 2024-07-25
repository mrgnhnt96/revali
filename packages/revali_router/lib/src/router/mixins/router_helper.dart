part of '../router.dart';

class RouterHelper with RouterHelperMixin {
  RouterHelper({
    required this.globalModifiers,
    required this.reflectHandler,
    required this.request,
    required this.response,
    required this.route,
    required this.debugErrorResponse,
    required this.debugResponses,
    required this.defaultResponses,
  }) {
    dataHandler = DataHandler();
    directMeta = route.getMeta();
    inheritedMeta = route.getMeta(inherit: true);
    globalModifiers.getMeta(handler: inheritedMeta);
  }

  @override
  late final DataHandler dataHandler;

  @override
  late final MetaHandler directMeta;

  @override
  final RouteModifiers globalModifiers;

  @override
  late final MetaHandler inheritedMeta;

  @override
  final ReflectHandler reflectHandler;

  @override
  final MutableRequest request;

  @override
  final MutableResponse response;

  @override
  final BaseRoute route;

  @override
  final DebugErrorResponse debugErrorResponse;

  @override
  final bool debugResponses;

  @override
  final DefaultResponses defaultResponses;
}
