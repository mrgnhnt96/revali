import 'package:revali_router/src/body/body_impl.dart';
import 'package:revali_router/src/request/request_impl.dart';
import 'package:revali_router_core/revali_router_core.dart';

// ignore: must_be_immutable, public_member_api_docs
class WebSocketRequestImpl extends RequestImpl implements WebSocketRequest {
  // ignore: use_super_parameters
  WebSocketRequestImpl.fromRequest(
    FullRequest request,
    Future<void> Function(int code, String reason) close,
  )   : _originalBody = request.body,
        _close = close,
        super.fromRequest(request);

  var _hasOverridden = false;
  Body? _overrideBody;
  final Body _originalBody;

  @override
  Body get body {
    if (_overrideBody case final body? when _hasOverridden) {
      return body;
    }

    return _originalBody;
  }

  @override
  Future<void> resolvePayload() async {
    if (_overrideBody != null) return;

    return super.resolvePayload();
  }

  @override
  Future<void> overrideBody(Object? data) async {
    _hasOverridden = true;
    await (_overrideBody ??= BodyImpl()).replace(data);
  }

  final Future<void> Function(int code, String reason) _close;

  @override
  Future<void> close([
    int code = 1000,
    String reason = 'Closed by the server',
  ]) async {
    await _close(code, reason);
  }
}
