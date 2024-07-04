import 'package:revali_router/src/data/read_only_data_handler.dart';
import 'package:revali_router/src/exception_catcher/exception_catcher_context.dart';
import 'package:revali_router/src/exception_catcher/exception_catcher_meta_impl.dart';
import 'package:revali_router/src/request/read_only_request_context.dart';
import 'package:revali_router/src/response/mutable_response_context.dart';

class ExceptionCatcherContextImpl implements ExceptionCatcherContext {
  const ExceptionCatcherContextImpl({
    required this.data,
    required this.meta,
    required this.request,
    required this.response,
  });

  final ExceptionCatcherMetaImpl meta;
  @override
  final ReadOnlyDataHandler data;
  final ReadOnlyRequestContext request;
  final MutableResponseContext response;
}
