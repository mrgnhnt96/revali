import 'package:revali_router_core/data/data_handler.dart';
import 'package:revali_router_core/interceptor/interceptor_meta.dart';
import 'package:revali_router_core/reflect/reflect_handler.dart';
import 'package:revali_router_core/request/mutable_request_context.dart';
import 'package:revali_router_core/response/mutable_response_context.dart';

abstract class InterceptorContext {
  const InterceptorContext();

  InterceptorMeta get meta;
  DataHandler get data;
  MutableRequestContext get request;
  MutableResponseContext get response;
  ReflectHandler get reflect;
}
