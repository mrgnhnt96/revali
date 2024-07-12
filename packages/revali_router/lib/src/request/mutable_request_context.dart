import 'package:revali_router/src/headers/mutable_headers.dart';
import 'package:revali_router/src/request/read_only_request_context.dart';

abstract class MutableRequestContext implements ReadOnlyRequestContext {
  const MutableRequestContext();

  MutableHeaders get headers;
}
