import 'package:revali_router/src/body/body_data.dart';
import 'package:revali_router/src/headers/mutable_headers.dart';
import 'package:revali_router/src/response/read_only_response_context.dart';

abstract class RestrictedMutableResponseContext
    implements ReadOnlyResponseContext {
  const RestrictedMutableResponseContext();

  MutableHeaders get headers;

  BodyData? get body;

  set body(Object? data);
}
