part of '../router.dart';

mixin ContextMixin on HelperMixin {
  Context get main => ContextImpl(
        meta: meta,
        route: route,
        reflect: reflectHandler,
        request: request,
        data: data,
        response: response,
      );

  WebSocketContext get webSocket => WebSocketContextImpl(
        meta: main.meta,
        reflect: reflectHandler,
        request: request,
        response: response,
        data: data,
        close: close,
        asyncSender: asyncSender,
        route: route,
      );
}
