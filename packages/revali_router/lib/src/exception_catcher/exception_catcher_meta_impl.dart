import 'package:revali_router/src/meta/meta_arg_impl.dart';
import 'package:revali_router_core/revali_router_core.dart';

class ExceptionCatcherMetaImpl extends MetaArgImpl
    implements ExceptionCatcherMeta {
  const ExceptionCatcherMetaImpl({
    required super.direct,
    required super.inherited,
    required this.route,
  });

  @override
  final RouteEntry route;
}
