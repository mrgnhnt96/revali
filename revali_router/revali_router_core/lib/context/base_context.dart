import 'package:revali_router_core/revali_router_core.dart';

abstract class BaseContext {
  const BaseContext();

  DataHandler get data;
  ReadOnlyMeta get meta;
}
