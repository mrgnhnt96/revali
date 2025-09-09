import 'package:revali_router/src/meta/meta_detailed_impl.dart';
import 'package:revali_router_core/revali_router_core.dart';

class GuardMetaImpl extends MetaDetailedImpl implements GuardMeta {
  const GuardMetaImpl({
    required super.direct,
    required super.inherited,
    required this.route,
  });

  final RouteEntry route;
}
