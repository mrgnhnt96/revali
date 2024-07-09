import 'package:revali_router/src/meta/read_only_meta.dart';
import 'package:revali_router/src/meta/write_only_meta.dart';

class MetaHandler implements ReadOnlyMeta, WriteOnlyMeta {
  MetaHandler();

  Map<Type, List<dynamic>> _registered = {};

  /// Adds an instance to meta, which can be retrieved later.
  ///
  /// The key for the instance is the type of the instance.
  void add<T>(T instance) {
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
