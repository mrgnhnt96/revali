import 'package:revali_router/src/body/mutable_body_impl.dart';
import 'package:revali_router/src/request/mutable_request_impl.dart';
import 'package:revali_router_core/revali_router_core.dart';

class MutableWebSocketRequestImpl extends MutableRequestImpl
    implements MutableWebSocketRequest {
  // ignore: use_super_parameters
  MutableWebSocketRequestImpl.fromRequest(MutableRequest request)
      : _originalBody = request.body,
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
    (_overrideBody ??= MutableBodyImpl()).replace(data);
  }
}
