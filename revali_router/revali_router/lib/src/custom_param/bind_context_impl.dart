import 'package:revali_router_core/revali_router_core.dart';

class BindContextImpl implements BindContext {
  const BindContextImpl({
    required this.nameOfParameter,
    required this.parameterType,
    required this.data,
    required this.meta,
    required this.request,
    required this.response,
  });
  BindContextImpl.from(
    EndpointContext context, {
    required this.nameOfParameter,
    required this.parameterType,
  })  : data = context.data,
        meta = context.meta,
        request = context.request,
        response = context.response;

  @override
  final ReadOnlyData data;

  @override
  final ReadOnlyMeta meta;

  @override
  final ReadOnlyRequest request;

  @override
  final ReadOnlyResponse response;

  @override
  final String nameOfParameter;

  @override
  final Type parameterType;
}
