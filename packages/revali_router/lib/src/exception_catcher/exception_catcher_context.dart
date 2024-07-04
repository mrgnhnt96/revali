import 'package:revali_router/src/data/read_only_data_handler.dart';
import 'package:revali_router/src/exception_catcher/exception_catcher_meta.dart';
import 'package:revali_router/src/request/read_only_request_context.dart';
import 'package:revali_router/src/response/mutable_response_context.dart';

abstract class ExceptionCatcherContext {
  const ExceptionCatcherContext();

  ExceptionCatcherMeta get meta;
  ReadOnlyDataHandler get data;
  ReadOnlyRequestContext get request;
  MutableResponseContext get response;
}
