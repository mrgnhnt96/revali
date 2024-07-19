import 'package:revali_router_core/request/mutable_request.dart';

abstract class MutableWebSocketRequest implements MutableRequest {
  Future<void> overrideBody(Object? data);
}
