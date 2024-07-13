import 'package:revali_router_core/headers/mutable_headers.dart';
import 'package:revali_router_core/request/read_only_request_context.dart';
import 'package:revali_router_core/request/request_context.dart';

abstract class MutableRequestContext
    implements ReadOnlyRequestContext, RequestContext {
  const MutableRequestContext();

  MutableHeaders get headers;
}
