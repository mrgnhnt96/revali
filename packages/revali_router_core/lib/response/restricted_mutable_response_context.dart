import 'package:revali_router_core/body/body_data.dart';
import 'package:revali_router_core/headers/mutable_headers.dart';
import 'package:revali_router_core/response/read_only_response_context.dart';

abstract class RestrictedMutableResponseContext
    implements ReadOnlyResponseContext {
  const RestrictedMutableResponseContext();

  MutableHeaders get headers;

  BodyData? get body;

  set body(Object? data);
}
