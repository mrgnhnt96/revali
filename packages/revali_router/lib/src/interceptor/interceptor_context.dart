import 'package:revali_router/src/interceptor/interceptor_meta.dart';
import 'package:revali_router/src/request/mutable_request_context.dart';

class InterceptorContext extends MutableRequestContext {
  InterceptorContext(
    super.request, {
    required this.meta,
  });
  InterceptorContext.from(
    super.request, {
    required this.meta,
  }) : super.from();

  final InterceptorMeta meta;
}
