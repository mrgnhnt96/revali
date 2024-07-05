import 'package:revali_router/revali_router.dart';
import 'package:revali_router_annotations/custom_param/custom_param_context.dart';

class CustomParamContextImpl implements CustomParamContext {
  const CustomParamContextImpl({
    required this.name,
    required this.type,
    required this.data,
    required this.meta,
    required this.request,
    required this.response,
  });

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
