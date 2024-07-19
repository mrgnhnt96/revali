import 'package:revali_router_core/body/mutable_body.dart';
import 'package:revali_router_core/response/restricted_mutable_response.dart';

abstract class MutableResponse implements RestrictedMutableResponse {
  const MutableResponse();

  int get statusCode;
  void set statusCode(int value);

  @override
  MutableBody get body;
}
