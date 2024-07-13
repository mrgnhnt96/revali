import 'package:revali_router_core/data/data_handler.dart';
import 'package:revali_router_core/meta/read_only_meta.dart';
import 'package:revali_router_core/reflect/reflect_handler.dart';
import 'package:revali_router_core/request/mutable_request_context.dart';
import 'package:revali_router_core/response/mutable_response_context.dart';

abstract class EndpointContext {
  const EndpointContext();

  DataHandler get data;
  ReadOnlyMeta get meta;
  MutableRequestContext get request;
  MutableResponseContext get response;
  ReflectHandler get reflect;
}
