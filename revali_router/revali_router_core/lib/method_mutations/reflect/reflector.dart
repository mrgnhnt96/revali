import 'package:revali_router_core/meta/meta.dart';

class Reflector {
  final Map<String, Meta> _meta = {};

  Map<String, Meta> get meta => Map.unmodifiable(_meta);

  Meta operator [](String key) {
    return _meta[key] ??= Meta();
  }

  Meta get(String key) => this[key];
}
