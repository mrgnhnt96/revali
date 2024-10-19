part of '../router.dart';

class Helper with HelperMixin, ContextMixin {
  Helper({
    required this.route,
    required this.request,
    required Router router,
  }) {
    globalComponents = router._globalComponents ?? LifecycleComponentsImpl();
    reflectHandler = ReflectHandler(router._reflects);
    debugErrorResponse = router._debugResponse;
    debugResponses = router.debug;
    defaultResponses = router.defaultResponses;

    dataHandler = DataHandler();
    directMeta = route.getMeta();
    inheritedMeta = route.getMeta(inherit: true);
    globalComponents.getMeta(handler: inheritedMeta);
    response = MutableResponseImpl(requestHeaders: request.headers);
  }

  @override
  late final DataHandler dataHandler;

  @override
  late final MetaHandler directMeta;

  @override
  late final LifecycleComponents globalComponents;

  @override
  late final MetaHandler inheritedMeta;

  @override
  late final ReflectHandler reflectHandler;

  @override
  final FullRequest request;

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
  ContextMixin get context => this;

  @override
  RunMixin get run => Run(this);
}
