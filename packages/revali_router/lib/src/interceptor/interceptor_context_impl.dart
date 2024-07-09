import 'package:revali_router/src/data/data_handler.dart';
import 'package:revali_router/src/interceptor/interceptor_context.dart';
import 'package:revali_router/src/interceptor/interceptor_meta.dart';
import 'package:revali_router/src/reflect/reflect_handler.dart';
import 'package:revali_router/src/request/mutable_request_context.dart';
import 'package:revali_router/src/response/mutable_response_context.dart';

class InterceptorContextImpl implements InterceptorContext {
  const InterceptorContextImpl({
    required this.meta,
    required this.data,
    required this.request,
    required this.response,
    required this.reflect,
  });

  @override
  final InterceptorMeta meta;

  @override
  final DataHandler data;

  @override
  final MutableRequestContext request;

  @override
  final MutableResponseContext response;

  @override
  final ReflectHandler reflect;
}
