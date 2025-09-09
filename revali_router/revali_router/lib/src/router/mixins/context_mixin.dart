part of '../router.dart';

mixin ContextMixin on HelperMixin {
  Context get main => ContextImpl(
        meta: MetaImpl(
          direct: directMeta,
          inherited: inheritedMeta,
        ),
        route: route,
        reflect: reflectHandler,
        request: request,
        data: dataHandler,
        response: response,
      );

  WebSocketContext get webSocket => WebSocketContextImpl(
        meta: main.meta,
        reflect: reflectHandler,
        request: request,
        response: response,
        data: dataHandler,
        close: close,
        asyncSender: asyncSender,
        route: route,
      );
}
