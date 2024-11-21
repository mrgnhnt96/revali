part of 'router.dart';

class RunOptions {
  const RunOptions(this.helper);

  final HelperMixin helper;

  ReadOnlyResponse? call() => run();

  ReadOnlyResponse? run() {
    final HelperMixin(
      :request,
      :response,
    ) = helper;

    if (request.method != 'OPTIONS') {
      return null;
    }

    return response;
  }
}
