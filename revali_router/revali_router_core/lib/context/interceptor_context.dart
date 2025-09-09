import 'package:revali_router_core/context/base_context.dart';
import 'package:revali_router_core/response/mutable_response.dart';
import 'package:revali_router_core/response/read_only_response.dart';
import 'package:revali_router_core/response/restricted_mutable_response.dart';

@Deprecated('Use `Context` instead')
typedef RestrictedInterceptorContext
    = InterceptorContext<RestrictedMutableResponse>;
@Deprecated('Use `Context` instead')
typedef FullInterceptorContext = InterceptorContext<MutableResponse>;

@Deprecated('Use `Context` instead')
abstract class InterceptorContext<T extends ReadOnlyResponse>
    implements BaseContext {
  @Deprecated('Use `Context` instead')
  const InterceptorContext();
}
