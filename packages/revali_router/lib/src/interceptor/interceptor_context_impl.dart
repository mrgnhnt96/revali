import 'package:revali_router/src/interceptor/interceptor_context.dart';

// ignore: must_be_immutable
class InterceptorContextImpl extends InterceptorContext {
  InterceptorContextImpl(
    super.request, {
    required super.meta,
  });
  InterceptorContextImpl.from(
    super.request, {
    required super.meta,
  }) : super.from();
}
