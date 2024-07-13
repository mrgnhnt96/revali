import 'package:revali_router_core/revali_router_core.dart';

class MiddlewareContextImpl implements MiddlewareContext {
  const MiddlewareContextImpl({
    required this.data,
    required this.request,
    required this.response,
  });

  @override
  final DataHandler data;

  @override
  final MutableRequestContext request;

  @override
  final MutableResponseContext response;
}
