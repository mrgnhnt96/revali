import 'package:revali_router_core/data/read_only_data_handler.dart';
import 'package:revali_router_core/exception_catcher/exception_catcher_meta.dart';
import 'package:revali_router_core/request/read_only_request.dart';
import 'package:revali_router_core/response/mutable_response.dart';

abstract class ExceptionCatcherContext {
  const ExceptionCatcherContext();

  ExceptionCatcherMeta get meta;
  ReadOnlyDataHandler get data;
  ReadOnlyRequest get request;
  MutableResponse get response;
}
