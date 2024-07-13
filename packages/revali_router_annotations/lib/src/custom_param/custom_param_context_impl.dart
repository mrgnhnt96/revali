import 'package:revali_router_annotations/src/custom_param/custom_param_context.dart';
import 'package:revali_router_core/revali_router_core.dart';

class CustomParamContextImpl implements CustomParamContext {
  const CustomParamContextImpl({
    required this.name,
    required this.type,
    required this.data,
    required this.meta,
    required this.request,
    required this.response,
  });
  CustomParamContextImpl.from(
    EndpointContext context, {
    required this.name,
    required this.type,
  })  : data = context.data,
        meta = context.meta,
        request = context.request,
        response = context.response;

  @override
  final ReadOnlyDataHandler data;

  @override
  final ReadOnlyMeta meta;

  @override
  final ReadOnlyRequestContext request;

  @override
  final ReadOnlyResponseContext response;

  @override
  final String name;

  @override
  final Type type;
}
