part of './router.dart';

class RunInterceptors {
  const RunInterceptors(this.helper);

  final RouterHelperMixin helper;

  Future<void> pre() async {
    final RouterHelperMixin(
      :interceptors,
      context: ContextHelperMixin(interceptor: context),
    ) = helper;

    for (final interceptor in interceptors) {
      await interceptor.pre(context);
    }
  }

  Future<void> post() async {
    final RouterHelperMixin(
      :interceptors,
      context: ContextHelperMixin(interceptor: context),
    ) = helper;

    for (final interceptor in interceptors) {
      await interceptor.post(context);
    }
  }
}
