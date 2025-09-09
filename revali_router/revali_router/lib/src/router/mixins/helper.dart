// ignore_for_file: avoid_setters_without_getters

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

    data = DataImpl()..add<CleanUp>(CleanUpImpl());
    meta = MetaScopeImpl(
      direct: route.getMeta(),
      inherited: route.getMeta(inherit: true),
    );
    globalComponents.getMeta(handler: meta);
    response = MutableResponseImpl(requestHeaders: request.headers);
    _request = request;
  }

  @override
  late final Data data;

  @override
  late final MetaScope meta;

  @override
  late final LifecycleComponents globalComponents;

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

  MutableWebSocketRequest? _webSocketRequest;
  @override
  set webSocketRequest(MutableWebSocketRequest request) {
    _webSocketRequest = request;
  }

  void Function(dynamic data)? _webSocketSender;
  @override
  set webSocketSender(void Function(dynamic data) sender) {
    _webSocketSender = sender;
  }

  @override
  AsyncWebSocketSender<dynamic> get asyncSender =>
      AsyncWebSocketSenderImpl<dynamic>((data) {
        _webSocketSender?.call(data);
      });

  @override
  CloseWebSocket get close => CloseWebSocketImpl((code, reason) async {
        await _webSocketRequest?.close(code, reason);
      });
}
