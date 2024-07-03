import 'package:revali_router/src/meta/meta_arg.dart';
import 'package:revali_router/src/route/route_entry.dart';

class GuardMeta extends MetaArg {
  const GuardMeta({
    required super.direct,
    required super.inherited,
    required this.route,
  });

  final RouteEntry route;
}
