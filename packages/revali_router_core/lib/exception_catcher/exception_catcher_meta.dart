import 'package:revali_router_core/meta/read_only_meta_arg.dart';
import 'package:revali_router_core/route/route_entry.dart';

abstract class ExceptionCatcherMeta implements ReadOnlyMetaArg {
  const ExceptionCatcherMeta();

  RouteEntry get route;
}
