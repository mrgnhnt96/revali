import 'package:revali_router_core/meta/meta.dart';

abstract class ReadOnlyReflector {
  const ReadOnlyReflector();

  Map<String, Meta> get meta;

  Meta operator [](String key);

  Meta get(String key);
}
