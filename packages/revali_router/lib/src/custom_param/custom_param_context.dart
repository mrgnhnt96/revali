import 'package:revali_router/src/data/read_only_data_handler.dart';
import 'package:revali_router/src/meta/read_only_meta.dart';
import 'package:revali_router/src/request/read_only_request_context.dart';
import 'package:revali_router/src/response/read_only_response_context.dart';

abstract class CustomParamContext {
  const CustomParamContext();

  /// The name of the parameter that
  /// corresponds to the custom parameter annotation.
  String get name;

  /// The type of the parameter that
  /// corresponds to the custom parameter annotation.
  Type get type;

  ReadOnlyDataHandler get data;

  ReadOnlyMeta get meta;

  ReadOnlyRequestContext get request;

  ReadOnlyResponseContext get response;
}
