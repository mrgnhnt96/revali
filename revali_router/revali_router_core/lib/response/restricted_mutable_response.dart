import 'package:revali_router_core/body/body_data.dart';
import 'package:revali_router_core/headers/mutable_headers.dart';
import 'package:revali_router_core/response/read_only_response.dart';

abstract class RestrictedMutableResponse implements ReadOnlyResponse {
  const RestrictedMutableResponse();

  @override
  MutableHeaders get headers;

  set headers(MutableHeaders value);

  @override
  BodyData? get body;

  set body(Object? data);
}
