import 'package:revali_router_core/meta/read_only_meta_detailed.dart';
import 'package:revali_router_core/route/route_entry.dart';

abstract class ExceptionCatcherMeta implements ReadOnlyMetaDetailed {
  const ExceptionCatcherMeta();

  RouteEntry get route;
}
