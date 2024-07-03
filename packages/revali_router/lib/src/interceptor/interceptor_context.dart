import 'package:revali_router/src/data/data_handler.dart';
import 'package:revali_router/src/interceptor/interceptor_meta.dart';
import 'package:revali_router/src/request/mutable_request_context.dart';

abstract class InterceptorContext extends MutableRequestContext {
  const InterceptorContext();

  InterceptorMeta get meta;
  DataHandler get data;
}
