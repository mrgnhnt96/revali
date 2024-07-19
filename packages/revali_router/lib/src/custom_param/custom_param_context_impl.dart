import 'package:revali_router_core/revali_router_core.dart';

class CustomParamContextImpl implements CustomParamContext {
  const CustomParamContextImpl({
    required this.nameOfParameter,
    required this.parameterType,
    required this.data,
    required this.meta,
    required this.request,
    required this.response,
  });
  CustomParamContextImpl.from(
    EndpointContext context, {
    required this.nameOfParameter,
    required this.parameterType,
  })  : data = context.data,
        meta = context.meta,
        request = context.request,
        response = context.response;

  @override
  final ReadOnlyDataHandler data;

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
