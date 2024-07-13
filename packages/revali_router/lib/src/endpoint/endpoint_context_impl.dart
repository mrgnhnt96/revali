import 'package:revali_router_core/revali_router_core.dart';

class EndpointContextImpl implements EndpointContext {
  const EndpointContextImpl({
    required this.data,
    required this.meta,
    required this.reflect,
    required this.request,
    required this.response,
  });

  @override
  final DataHandler data;

  @override
  final ReadOnlyMeta meta;

  @override
  final MutableRequestContext request;

  @override
  final MutableResponseContext response;

  @override
  final ReflectHandler reflect;
}
