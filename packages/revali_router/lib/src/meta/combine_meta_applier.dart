import 'package:revali_router/src/meta/combine_meta.dart';
import 'package:revali_router/src/route/route.dart';

class CombineMetaApplier {
  const CombineMetaApplier(this.route, this.combine);

  final Route route;
  final List<CombineMeta> combine;

  void apply() {
    for (final c in combine) {
      route.guards.addAll(c.guards);
      route.middlewares.addAll(c.middlewares);
      route.interceptors.addAll(c.interceptors);
      route.catchers.addAll(c.catchers);
    }
  }
}
