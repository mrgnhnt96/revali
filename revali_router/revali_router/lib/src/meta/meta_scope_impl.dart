import 'package:revali_router_core/meta/meta_scope.dart';
import 'package:revali_router_core/revali_router_core.dart';

class MetaScopeImpl implements MetaScope {
  MetaScopeImpl({
    required this.direct,
    required this.inherited,
  });

  @override
  final Meta direct;

  @override
  final Meta inherited;

  @override
  void add<T>(T instance) {
    direct.add<T>(instance);
  }

  @override
  List<T>? get<T>() {
    return direct.get<T>() ?? inherited.get<T>();
  }

  @override
  bool has<T>() {
    if (direct.has<T>()) {
      return true;
    }

    return inherited.has<T>();
  }
}
