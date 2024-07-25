part of '../router.dart';

class RouterHelper with RouterHelperMixin, ContextHelperMixin {
  RouterHelper({
    required this.route,
    required this.request,
    required Router router,
  }) {
    globalModifiers = router._globalModifiers ?? RouteModifiersImpl();
    reflectHandler = ReflectHandler(router._reflects);
    debugErrorResponse = router._debugResponse;
    debugResponses = router.debug;
    defaultResponses = router.defaultResponses;

    dataHandler = DataHandler();
    directMeta = route.getMeta();
    inheritedMeta = route.getMeta(inherit: true);
    globalModifiers.getMeta(handler: inheritedMeta);
    response = MutableResponseImpl(requestHeaders: request.headers);
  }

  @override
  late final DataHandler dataHandler;

  @override
  late final MetaHandler directMeta;

  @override
  late final RouteModifiers globalModifiers;

  @override
  late final MetaHandler inheritedMeta;

  @override
  late final ReflectHandler reflectHandler;

  @override
  final MutableRequest request;

  @override
  late final MutableResponse response;

  @override
  final BaseRoute route;

  @override
  late final DebugErrorResponse debugErrorResponse;

  @override
  late final bool debugResponses;

  @override
  late final DefaultResponses defaultResponses;

  @override
  ContextHelperMixin get context => this;

  @override
  RunnersHelperMixin get run => RunnersHelper(this);
}
