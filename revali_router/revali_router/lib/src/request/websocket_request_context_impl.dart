import 'package:revali_router/src/body/mutable_body_impl.dart';
import 'package:revali_router/src/request/mutable_request_impl.dart';
import 'package:revali_router_core/revali_router_core.dart';

// ignore: must_be_immutable, public_member_api_docs
class MutableWebSocketRequestImpl extends MutableRequestImpl
    implements MutableWebSocketRequest {
  // ignore: use_super_parameters
  MutableWebSocketRequestImpl.fromRequest(
    FullRequest request,
    Future<void> Function(int code, String reason) close,
  )   : _originalBody = request.body,
        _close = close,
        super.fromRequest(request);

  var _hasOverridden = false;
  MutableBody? _overrideBody;
  final ReadOnlyBody _originalBody;

  @override
  ReadOnlyBody get body {
    if (_overrideBody case final body? when _hasOverridden) {
      return body;
    }

    return _originalBody;
  }

  @override
  Future<void> overrideBody(Object? data) async {
    _hasOverridden = true;
    await (_overrideBody ??= MutableBodyImpl()).replace(data);
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
