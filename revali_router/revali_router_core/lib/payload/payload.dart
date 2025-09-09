import 'package:revali_router_core/body/mutable_body.dart';
import 'package:revali_router_core/method_mutations/headers/read_only_headers.dart';
import 'package:revali_router_core/payload/read_only_payload.dart';

abstract class Payload implements ReadOnlyPayload {
  const Payload();

  Future<MutableBody> resolve(ReadOnlyHeaders headers);

  Future<void> close();
}
