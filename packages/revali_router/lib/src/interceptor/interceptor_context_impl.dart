import 'package:revali_router/src/interceptor/interceptor_context.dart';
import 'package:shelf/shelf.dart';

class InterceptorContextImpl extends InterceptorContext {
  InterceptorContextImpl(
    super.request, {
    required super.meta,
  });
  InterceptorContextImpl.from(
    super.request, {
    required super.meta,
  }) : super.from();

  Response getResponse() {
    return Response.ok({'data': 'Hello, World!'});
  }
}
