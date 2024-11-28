import 'package:revali_router_core/meta/meta_detailed.dart';
import 'package:revali_router_core/route/route_entry.dart';

abstract class ExceptionCatcherMeta implements MetaDetailed {
  const ExceptionCatcherMeta();

  RouteEntry get route;
}
