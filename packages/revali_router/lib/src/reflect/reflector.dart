import 'package:revali_router/src/meta/meta_handler.dart';
import 'package:revali_router/src/meta/write_only_meta.dart';
import 'package:revali_router/src/reflect/write_only_reflector.dart';

class Reflector implements WriteOnlyReflector {
  final Map<String, WriteOnlyMeta> _meta = {};

  Map<String, MetaHandler> get meta => Map.unmodifiable(_meta);

  WriteOnlyMeta operator [](String key) {
    return _meta[key] ??= MetaHandler();
  }
}
