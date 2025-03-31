import 'package:revali_router_core/revali_router_core.dart';

class CloseWebSocketImpl implements CloseWebSocket {
  const CloseWebSocketImpl(this._close);

  final Future<void> Function(int code, String reason) _close;

  @override
  void call([int code = 1000, String reason = 'Closed by the server']) {
    close(code, reason);
  }

  @override
  Future<void> close([
    int code = 1000,
    String reason = 'Closed by the server',
  ]) async {
    await _close(code, reason);
  }
}
