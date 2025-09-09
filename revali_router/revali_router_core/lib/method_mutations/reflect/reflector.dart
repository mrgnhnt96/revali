import 'package:revali_router_core/meta/meta_handler.dart';
import 'package:revali_router_core/meta/read_only_meta.dart';
import 'package:revali_router_core/method_mutations/reflect/read_only_reflector.dart';
import 'package:revali_router_core/method_mutations/reflect/write_only_reflector.dart';

class Reflector implements WriteOnlyReflector, ReadOnlyReflector {
  final Map<String, MetaHandler> _meta = {};

  @override
  Map<String, MetaHandler> get meta => Map.unmodifiable(_meta);

  @override
  MetaHandler operator [](String key) {
    return _meta[key] ??= MetaHandler();
  }

  @override
  ReadOnlyMeta get(String key) => this[key];
}
