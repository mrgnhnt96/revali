import 'package:revali_router_core/meta/read_only_meta_arg.dart';

abstract class MetaArg implements ReadOnlyMetaArg {
  const MetaArg();

  List<T>? get<T>();
  bool has<T>();
}
