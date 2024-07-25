part of 'router.dart';

class RunRedirect {
  const RunRedirect(this.helper);

  final RouterHelperMixin helper;

  ReadOnlyResponse? call() => run();

  ReadOnlyResponse? run() {
    final RouterHelperMixin(
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
