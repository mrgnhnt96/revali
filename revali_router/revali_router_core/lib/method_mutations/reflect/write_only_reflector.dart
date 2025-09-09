import 'package:revali_router_core/meta/meta.dart';

abstract class WriteOnlyReflector {
  const WriteOnlyReflector();

  Meta operator [](String key);
}
