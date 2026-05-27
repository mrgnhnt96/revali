import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart' show Payload;
import 'package:revali_router_core/payload/payload.dart' show Payload;
import 'package:revali_router_core/revali_router_core.dart' show Payload;
import 'package:revali_server/converters/base_parameter_annotation.dart';
import 'package:revali_server/converters/server_body_annotation.dart';
import 'package:revali_server/converters/server_param.dart';

/// Whether [param] is `@Body() Stream<List<int>>` (or nested byte stream).
bool isByteStreamBodyParam(ServerParam param) {
  return param.annotations.body != null &&
      param.type.isStream &&
      param.type.isBytes;
}

/// Whether the route handler must materialize the payload before invoking the
/// controller. Byte-stream body params read directly from [Payload.read].
bool routeNeedsResolvePayload(Iterable<ServerParam> params) {
  return params.any(
    (param) => param.annotations.body != null && !isByteStreamBodyParam(param),
  );
}

bool byteStreamBodyHasAccess(BaseParameterAnnotation annotation) {
  return annotation is ServerBodyAnnotation &&
      (annotation.access?.isNotEmpty ?? false);
}

Expression createOriginalPayloadStreamVar() {
  return refer(
    'context',
  ).property('request').property('originalPayload').property('read').call([]);
}
