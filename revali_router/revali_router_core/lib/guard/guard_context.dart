import 'package:revali_router_core/data/data_handler.dart';
import 'package:revali_router_core/guard/guard_meta.dart';
import 'package:revali_router_core/request/read_only_request.dart';
import 'package:revali_router_core/response/restricted_mutable_response.dart';

abstract class GuardContext {
  const GuardContext();

  GuardMeta get meta;
  DataHandler get data;
  ReadOnlyRequest get request;
  RestrictedMutableResponse get response;
}
