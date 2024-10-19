import 'package:revali_router_core/revali_router_core.dart';

class ExceptionCatcherContextImpl implements ExceptionCatcherContext {
  const ExceptionCatcherContextImpl({
    required this.data,
    required this.meta,
    required this.request,
    required this.response,
  });

  @override
  final ExceptionCatcherMeta meta;
  @override
  final ReadOnlyDataHandler data;
  @override
  final ReadOnlyRequest request;
  @override
  final MutableResponse response;
}
