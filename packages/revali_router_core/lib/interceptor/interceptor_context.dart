import 'package:revali_router_core/data/data_handler.dart';
import 'package:revali_router_core/interceptor/interceptor_meta.dart';
import 'package:revali_router_core/reflect/read_only_reflect_handler.dart';
import 'package:revali_router_core/request/mutable_request.dart';
import 'package:revali_router_core/response/mutable_response.dart';

abstract class InterceptorContext {
  const InterceptorContext();

  InterceptorMeta get meta;
  DataHandler get data;
  MutableRequest get request;
  MutableResponse get response;
  ReadOnlyReflectHandler get reflect;
}
