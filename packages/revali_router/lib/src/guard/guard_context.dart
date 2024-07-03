import 'package:revali_router/src/guard/guard_meta.dart';
import 'package:revali_router/src/request/mutable_request_context.dart';

// ignore: must_be_immutable
class GuardContext extends MutableRequestContext {
  GuardContext(
    super.request, {
    required this.meta,
  });
  GuardContext.from(
    super.request, {
    required this.meta,
  }) : super.from();

  final GuardMeta meta;
}
