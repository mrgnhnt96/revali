import 'package:revali_router_core/context/base_context.dart';
import 'package:revali_router_core/request/read_only_request.dart';
import 'package:revali_router_core/response/restricted_mutable_response.dart';

abstract class GuardContext implements BaseContext {
  const GuardContext();

  ReadOnlyRequest get request;
  RestrictedMutableResponse get response;
}
