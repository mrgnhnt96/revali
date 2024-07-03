import 'package:revali_router/src/guard/guard_context.dart';
import 'package:revali_router/src/guard/guard_meta.dart';
import 'package:revali_router/src/request/mutable_request_context_impl.dart';

// ignore: must_be_immutable
class GuardContextImpl extends MutableRequestContextImpl
    implements GuardContext {
  GuardContextImpl(
    super.request, {
    required this.meta,
  });
  GuardContextImpl.from(
    super.request, {
    required this.meta,
  }) : super.from();

  @override
  final GuardMeta meta;
}
