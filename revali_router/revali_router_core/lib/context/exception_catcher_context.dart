import 'package:revali_router_core/data/data.dart';
import 'package:revali_router_core/meta/meta.dart';
import 'package:revali_router_core/request/read_only_request.dart';
import 'package:revali_router_core/response/mutable_response.dart';

@Deprecated('Use `Context` instead')
abstract class ExceptionCatcherContext {
  @Deprecated('Use `Context` instead')
  const ExceptionCatcherContext();

  Meta get meta;
  Data get data;
  ReadOnlyRequest get request;
  MutableResponse get response;
}
