import 'package:revali_router_core/revali_router_core.dart';

class MiddlewareContextImpl implements MiddlewareContext {
  const MiddlewareContextImpl({
    required this.meta,
    required this.data,
    required this.request,
    required this.response,
  });

  @override
  final DataHandler data;

  @override
  final MutableRequest request;

  @override
  final MutableResponse response;

  @override
  final ReadOnlyMeta meta;
}
