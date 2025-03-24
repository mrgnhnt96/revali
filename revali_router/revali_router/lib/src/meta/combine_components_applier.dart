import 'package:revali_router_core/revali_router_core.dart';

class CombineComponentsApplier {
  const CombineComponentsApplier(this.route, this.combine);

  final LifecycleComponents route;
  final List<CombineComponents> combine;

  void apply() {
    for (final c in combine) {
      route.guards.addAll(c.guards);
      route.middlewares.addAll(c.middlewares);
      route.interceptors.addAll(c.interceptors);
      route.catchers.addAll(c.catchers);
    }
  }
}
