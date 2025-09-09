import 'package:revali_router_core/body/mutable_body.dart';
import 'package:revali_router_core/method_mutations/headers/mutable_headers.dart';
import 'package:revali_router_core/response/restricted_mutable_response.dart';

abstract class MutableResponse implements RestrictedMutableResponse {
  const MutableResponse();

  @override
  int get statusCode;
  set statusCode(int value);

  @override
  MutableBody get body;

  @override
  MutableHeaders get joinedHeaders;
}
