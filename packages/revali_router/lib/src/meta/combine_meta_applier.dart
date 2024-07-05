import 'package:revali_router/src/meta/combine_meta.dart';
import 'package:revali_router/src/route/route.dart';

class CombineMetaApplier {
  const CombineMetaApplier(this.route, this.combine);

  final Route route;
  final CombineMeta? combine;

  void apply() {
    final combine = this.combine;
    if (combine == null) {
      return;
    }

    route.guards.addAll(combine.guards);
    route.middlewares.addAll(combine.middleware);
    route.interceptors.addAll(combine.interceptors);
    route.catchers.addAll(combine.catchers);
  }
}
