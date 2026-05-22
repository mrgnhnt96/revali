part of 'router.dart';

class RunWrappers {
  const RunWrappers(this.helper);

  final HelperMixin helper;

  Future<Response> run(Future<Response> Function() inner) async {
    final HelperMixin(
      :requestWrappers,
      context: ContextMixin(main: context),
    ) = helper;

    var chain = inner;

    for (final wrapper in requestWrappers.toList().reversed) {
      final next = chain;
      final current = wrapper;
      chain = () => current.wrap(context, next);
    }

    return chain();
  }
}
