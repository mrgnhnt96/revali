import 'package:revali_router_core/body/mutable_body.dart';
import 'package:revali_router_core/method_mutations/headers/mutable_headers.dart';
import 'package:revali_router_core/request/read_only_request.dart';

abstract class MutableRequest implements ReadOnlyRequest {
  const MutableRequest();

  @override
  MutableHeaders get headers;

  @override
  MutableBody get body;
}
