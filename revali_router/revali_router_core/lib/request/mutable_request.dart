import 'package:revali_router_core/headers/mutable_headers.dart';
import 'package:revali_router_core/request/read_only_request.dart';

abstract class MutableRequest implements ReadOnlyRequest {
  const MutableRequest();

  @override
  MutableHeaders get headers;
}
