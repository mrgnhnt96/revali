import 'package:revali_router_core/request/full_request.dart';

abstract class MutableWebSocketRequest implements FullRequest {
  Future<void> overrideBody(Object? data);

  @override
  Future<void> close([
    int code = 1000,
    String reason = 'Closed by the server',
  ]);
}
