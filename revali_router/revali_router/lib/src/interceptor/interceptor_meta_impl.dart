import 'package:revali_router/src/meta/meta_arg_impl.dart';
import 'package:revali_router_core/revali_router_core.dart';

class InterceptorMetaImpl extends MetaArgImpl implements InterceptorMeta {
  const InterceptorMetaImpl({
    required super.direct,
    required super.inherited,
  });
}
