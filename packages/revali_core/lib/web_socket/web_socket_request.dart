import 'package:revali_core/request/full_request.dart';

abstract class WebSocketRequest implements FullRequest {
  Future<void> overrideBody(Object? data);

  @override
  Future<void> close([
    int code = 1000,
    String reason = 'Closed by the server',
  ]);
}
