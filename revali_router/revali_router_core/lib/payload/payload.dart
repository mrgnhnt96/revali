import 'package:revali_router_core/body/body_data.dart';
import 'package:revali_router_core/headers/read_only_headers.dart';
import 'package:revali_router_core/payload/read_only_payload.dart';

abstract class Payload implements ReadOnlyPayload {
  const Payload();

  Future<BodyData> resolve(ReadOnlyHeaders headers);
}
