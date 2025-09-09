import 'package:revali_router_core/data/read_only_data.dart';
import 'package:revali_router_core/meta/exception_catcher_meta.dart';
import 'package:revali_router_core/request/read_only_request.dart';
import 'package:revali_router_core/response/mutable_response.dart';

@Deprecated('Use `Context` instead')
abstract class ExceptionCatcherContext {
  @Deprecated('Use `Context` instead')
  const ExceptionCatcherContext();

  ExceptionCatcherMeta get meta;
  ReadOnlyData get data;
  ReadOnlyRequest get request;
  MutableResponse get response;
}
