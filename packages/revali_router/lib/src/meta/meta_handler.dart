import 'package:revali_router/src/meta/read_only_meta.dart';

class MetaHandler implements ReadOnlyMeta {
  MetaHandler();

  Map<Type, List<dynamic>> _registered = {};

  void register<T>(T instance) {
    (_registered[T] ??= []).add(instance);
  }

  @override
  List<T>? get<T>() {
    final result = _registered[T];

    return List<T>.from(result as List<T>, growable: false);
  }

  @override
  bool has<T>() {
    return _registered.containsKey(T);
  }
}
