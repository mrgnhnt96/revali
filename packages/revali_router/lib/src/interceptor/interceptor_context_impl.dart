import 'package:revali_router/src/interceptor/interceptor_context.dart';
import 'package:revali_router/src/interceptor/interceptor_meta.dart';
import 'package:revali_router/src/request/mutable_request_context_impl.dart';

// ignore: must_be_immutable
class InterceptorContextImpl extends MutableRequestContextImpl
    implements InterceptorContext {
  InterceptorContextImpl(
    super.request, {
    required this.meta,
  });
  InterceptorContextImpl.from(
    super.request, {
    required this.meta,
  }) : super.from();

  final InterceptorMeta meta;
}
