import 'package:revali_router/src/meta/meta_detailed_impl.dart';
import 'package:revali_router_core/revali_router_core.dart';

class MetaImpl implements Meta {
  MetaImpl({
    required this.direct,
    required this.inherited,
  }) : all = MetaDetailedImpl(
          direct: direct,
          inherited: inherited,
        );

  @override
  final MetaHandler direct;

  @override
  final MetaHandler inherited;

  @override
  final MetaHandler all;
}
