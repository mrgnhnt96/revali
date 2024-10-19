import 'package:revali_router_core/meta/meta_arg.dart';
import 'package:revali_router_core/route/route_entry.dart';

abstract class ExceptionCatcherMeta implements MetaArg {
  const ExceptionCatcherMeta();

  RouteEntry get route;
}
