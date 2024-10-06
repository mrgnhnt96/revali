import 'package:revali_router_core/meta/read_only_meta.dart';

abstract class ReadOnlyReflector {
  const ReadOnlyReflector();

  Map<String, ReadOnlyMeta> get meta;

  ReadOnlyMeta operator [](String key);

  ReadOnlyMeta get(String key);
}
