part of '../router.dart';

mixin ContextMixin on HelperMixin {
  EndpointContext get endpoint => EndpointContextImpl(
        meta: directMeta,
        reflect: reflectHandler,
        request: request,
        data: dataHandler,
        response: response,
      );

  WebSocketContext get webSocket => WebSocketContextImpl(
        meta: directMeta,
        reflect: reflectHandler,
        request: request,
        response: response,
        data: dataHandler,
        close: close,
        asyncSender: asyncSender,
      );

  ExceptionCatcherContext get exceptionCatcher => ExceptionCatcherContextImpl(
        data: dataHandler,
        meta: ExceptionCatcherMetaImpl(
          direct: directMeta,
          inherited: inheritedMeta,
          route: route,
        ),
        request: request,
        response: response,
      );

  GuardContext get guard => GuardContextImpl(
        meta: GuardMetaImpl(
          direct: directMeta,
          inherited: inheritedMeta,
          route: route,
        ),
        response: response,
        request: request,
        data: dataHandler,
      );

  InterceptorContext<MutableResponse> get interceptor => InterceptorContextImpl(
        meta: InterceptorMetaImpl(
          direct: directMeta,
          inherited: inheritedMeta,
        ),
        reflect: reflectHandler,
        request: request,
        response: response,
        data: dataHandler,
      );

  MiddlewareContext get middleware => MiddlewareContextImpl(
        meta: MetaDetailedImpl(
          direct: directMeta,
          inherited: inheritedMeta,
        ),
        request: request,
        response: response,
        data: dataHandler,
      );
}
