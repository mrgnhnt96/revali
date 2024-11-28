import 'package:revali_router_core/context/base_context.dart';
import 'package:revali_router_core/reflect/read_only_reflect_handler.dart';
import 'package:revali_router_core/request/mutable_request.dart';
import 'package:revali_router_core/response/mutable_response.dart';
import 'package:revali_router_core/response/read_only_response.dart';
import 'package:revali_router_core/response/restricted_mutable_response.dart';

typedef RestrictedInterceptorContext
    = InterceptorContext<RestrictedMutableResponse>;
typedef FullInterceptorContext = InterceptorContext<MutableResponse>;

abstract class InterceptorContext<T extends ReadOnlyResponse>
    implements BaseContext {
  const InterceptorContext();

  MutableRequest get request;
  T get response;
  ReadOnlyReflectHandler get reflect;
}
