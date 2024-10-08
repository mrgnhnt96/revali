import 'package:revali_router_core/meta/read_only_meta.dart';
import 'package:revali_router_core/meta/write_only_meta.dart';

class MetaHandler implements ReadOnlyMeta, WriteOnlyMeta {
  MetaHandler();

  final _registered = <Type, List<dynamic>>{};

  /// Adds an instance to meta, which can be retrieved later.
  ///
  /// The key for the instance is the type of the instance.
  @override
  void add<T>(T instance) {
    (_registered[T] ??= []).add(instance);
  }

  @override
  List<T>? get<T>() {
    final result = _registered[T];

    return List<T>.from(result! as List<T>, growable: false);
  }

  @override
  bool has<T>() {
    return _registered.containsKey(T);
  }
}
