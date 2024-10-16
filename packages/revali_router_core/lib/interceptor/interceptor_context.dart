import 'package:revali_router_core/data/data_handler.dart';
import 'package:revali_router_core/interceptor/interceptor_meta.dart';
import 'package:revali_router_core/reflect/read_only_reflect_handler.dart';
import 'package:revali_router_core/request/mutable_request.dart';
import 'package:revali_router_core/response/mutable_response.dart';
import 'package:revali_router_core/response/read_only_response.dart';
import 'package:revali_router_core/response/restricted_mutable_response.dart';

abstract class InterceptorContext<T extends ReadOnlyResponse> {
  const InterceptorContext();

  InterceptorMeta get meta;
  DataHandler get data;
  MutableRequest get request;
  T get response;
  ReadOnlyReflectHandler get reflect;
}

abstract class RestrictedInterceptorContext
    extends InterceptorContext<RestrictedMutableResponse> {
  const RestrictedInterceptorContext();
}

abstract class FullInterceptorContext
    extends InterceptorContext<MutableResponse> {
  const FullInterceptorContext();
}
