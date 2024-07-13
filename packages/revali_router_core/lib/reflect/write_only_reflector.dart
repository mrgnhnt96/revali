import 'package:revali_router_core/meta/write_only_meta.dart';

abstract class WriteOnlyReflector {
  const WriteOnlyReflector();

  WriteOnlyMeta operator [](String key);
}
