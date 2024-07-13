import 'package:revali_router_core/revali_router_core.dart';

final class GuardContextImpl implements GuardContext {
  const GuardContextImpl({
    required this.meta,
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

  @override
  final GuardMeta meta;
}
