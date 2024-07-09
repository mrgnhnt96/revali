import 'package:revali_router/src/data/data_handler.dart';
import 'package:revali_router/src/meta/read_only_meta.dart';
import 'package:revali_router/src/reflect/reflect_handler.dart';
import 'package:revali_router/src/request/mutable_request_context.dart';
import 'package:revali_router/src/response/mutable_response_context.dart';

abstract class EndpointContext {
  const EndpointContext();

  DataHandler get data;
  ReadOnlyMeta get meta;
  MutableRequestContext get request;
  MutableResponseContext get response;
  ReflectHandler get reflect;
}
