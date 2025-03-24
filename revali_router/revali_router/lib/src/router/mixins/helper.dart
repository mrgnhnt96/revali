part of '../router.dart';

class Helper with HelperMixin, ContextMixin {
  Helper({
    required this.route,
    required FullRequest request,
    required Router router,
  }) {
    globalComponents = router._globalComponents ?? LifecycleComponentsImpl();
    reflectHandler = ReflectHandler(router._reflects);
    debugErrorResponse = router._debugResponse;
    debugResponses = router.debug;
    defaultResponses = router.defaultResponses;

    dataHandler = DataHandler()..add<CleanUp>(CleanUpImpl());
    directMeta = route.getMeta();
    inheritedMeta = route.getMeta(inherit: true);
    globalComponents.getMeta(handler: inheritedMeta);
    response = MutableResponseImpl(requestHeaders: request.headers);
    _request = request;
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
  FullRequest get request => _webSocketRequest ?? _request;
  late final FullRequest _request;

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

  @override
  // ignore: avoid_setters_without_getters
  set webSocketRequest(MutableWebSocketRequest request) {
    _webSocketRequest = request;
  }

  MutableWebSocketRequest? _webSocketRequest;
}
