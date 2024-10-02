part of './router.dart';

class RunInterceptors {
  const RunInterceptors(this.helper);

  final HelperMixin helper;

  Future<void> pre() async {
    final HelperMixin(
      :interceptors,
      context: ContextMixin(interceptor: context),
    ) = helper;

    for (final interceptor in interceptors) {
      await interceptor.pre(context);
    }
  }

  Future<void> post() async {
    final HelperMixin(
      :interceptors,
      context: ContextMixin(interceptor: context),
    ) = helper;

    for (final interceptor in interceptors.toList().reversed) {
      await interceptor.post(context);
    }
  }
}
