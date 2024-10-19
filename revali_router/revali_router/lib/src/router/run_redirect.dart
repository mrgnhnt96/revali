part of 'router.dart';

class RunRedirect {
  const RunRedirect(this.helper);

  final HelperMixin helper;

  ReadOnlyResponse? call() => run();

  ReadOnlyResponse? run() {
    final HelperMixin(
      :route,
    ) = helper;

    if (route.redirect case final redirect?) {
      return CannedResponse.redirect(
        redirect.path,
        statusCode: redirect.code,
      );
    }

    return null;
  }
}
