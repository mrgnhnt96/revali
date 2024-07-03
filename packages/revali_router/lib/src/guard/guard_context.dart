import 'package:revali_router/src/guard/guard_meta.dart';
import 'package:revali_router/src/request/mutable_request_context.dart';

abstract class GuardContext extends MutableRequestContext {
  GuardMeta get meta;
}
