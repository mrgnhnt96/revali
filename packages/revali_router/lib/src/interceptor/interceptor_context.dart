import 'package:revali_router/src/data/data_handler.dart';
import 'package:revali_router/src/interceptor/interceptor_meta.dart';
import 'package:revali_router/src/reflect/reflect_handler.dart';
import 'package:revali_router/src/request/mutable_request_context.dart';
import 'package:revali_router/src/response/mutable_response_context.dart';

abstract class InterceptorContext {
  const InterceptorContext();

  InterceptorMeta get meta;
  DataHandler get data;
  MutableRequestContext get request;
  MutableResponseContext get response;
  ReflectHandler get reflect;
}
