part of './router.dart';

class _RunInterceptors {
  const _RunInterceptors(this.helper);

  final RouterHelperMixin helper;

  Future<void> pre() async {
    final RouterHelperMixin(
      :request,
      :interceptors,
      :response,
      :dataHandler,
      :directMeta,
      :inheritedMeta,
      :reflectHandler,
    ) = helper;

    for (final interceptor in interceptors) {
      await interceptor.pre(
        InterceptorContextImpl(
          meta: InterceptorMetaImpl(
            direct: directMeta,
            inherited: inheritedMeta,
          ),
          reflect: reflectHandler,
          request: request,
          response: response,
          data: dataHandler,
        ),
      );
    }
  }

  Future<void> post() async {
    final RouterHelperMixin(
      :request,
      :interceptors,
      :response,
      :dataHandler,
      :directMeta,
      :inheritedMeta,
      :reflectHandler,
    ) = helper;

    for (final interceptor in interceptors) {
      await interceptor.post(
        InterceptorContextImpl(
          meta: InterceptorMetaImpl(
            direct: directMeta,
            inherited: inheritedMeta,
          ),
          reflect: reflectHandler,
          request: request,
          response: response,
          data: dataHandler,
        ),
      );
    }
  }
}
