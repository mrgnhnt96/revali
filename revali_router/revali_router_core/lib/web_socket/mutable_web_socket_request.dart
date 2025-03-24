import 'package:revali_router_core/request/full_request.dart';

abstract class MutableWebSocketRequest implements FullRequest {
  Future<void> overrideBody(Object? data);
}
