import 'package:revali_router/src/data/read_only_data_handler.dart';
import 'package:revali_router/src/meta/read_only_meta.dart';
import 'package:revali_router/src/request/read_only_request_context.dart';
import 'package:revali_router/src/response/read_only_response_context.dart';

import 'custom_param_context.dart';

class CustomParamContextImpl implements CustomParamContext {
  const CustomParamContextImpl({
    required this.name,
    required this.type,
    required this.data,
    required this.meta,
    required this.request,
    required this.response,
  });

  @override
  final ReadOnlyDataHandler data;

  @override
  final ReadOnlyMeta meta;

  @override
  final ReadOnlyRequestContext request;

  @override
  final ReadOnlyResponseContext response;

  @override
  final String name;

  @override
  final Type type;
}
