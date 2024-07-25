part of 'router.dart';

class RunOptions {
  const RunOptions(this.helper);

  final RouterHelperMixin helper;

  ReadOnlyResponse? call() => run();

  ReadOnlyResponse? run() {
    final RouterHelperMixin(
      :request,
      :route,
    ) = helper;

    if (request.method != 'OPTIONS') {
      return null;
    }

    return CannedResponse.options(
      allowedMethods: route.allowedMethods,
    );
  }
}
