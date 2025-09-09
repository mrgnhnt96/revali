import 'package:revali_router_core/meta/meta.dart';
import 'package:revali_router_core/method_mutations/reflect/read_only_reflector.dart';
import 'package:revali_router_core/method_mutations/reflect/write_only_reflector.dart';

class Reflector implements WriteOnlyReflector, ReadOnlyReflector {
  final Map<String, Meta> _meta = {};

  @override
  Map<String, Meta> get meta => Map.unmodifiable(_meta);

  @override
  Meta operator [](String key) {
    return _meta[key] ??= Meta();
  }

  @override
  Meta get(String key) => this[key];
}
