import 'package:revali_router/src/meta/read_only_meta_arg.dart';
import 'package:revali_router/src/route/route_entry.dart';

abstract class ExceptionCatcherMeta implements ReadOnlyMetaArg {
  const ExceptionCatcherMeta();

  RouteEntry get route;
}
