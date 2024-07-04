import 'package:revali_router/src/exception_catcher/exception_catcher_meta.dart';
import 'package:revali_router/src/meta/meta_arg.dart';
import 'package:revali_router/src/route/route_entry.dart';

class ExceptionCatcherMetaImpl extends MetaArg implements ExceptionCatcherMeta {
  const ExceptionCatcherMetaImpl({
    required super.direct,
    required super.inherited,
    required this.route,
  });

  final RouteEntry route;
}
