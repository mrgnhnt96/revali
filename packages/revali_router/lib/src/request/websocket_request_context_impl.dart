import 'package:revali_router/revali_router.dart';
import 'package:revali_router/src/body/mutable_body.dart';
import 'package:revali_router/src/body/mutable_body_impl.dart';
import 'package:revali_router/src/body/read_only_body.dart';
import 'package:revali_router/src/request/web_socket_request_context.dart';

class WebSocketRequestContextImpl extends MutableRequestContextImpl
    implements WebSocketRequestContext {
  WebSocketRequestContextImpl.fromRequest(MutableRequestContextImpl request)
      : _originalBody = request.body,
        super.fromRequest(request);

  var _hasOverriden = false;
  MutableBody? _overrideBody;
  final ReadOnlyBody _originalBody;

  @override
  ReadOnlyBody get body {
    if (_overrideBody case final body? when _hasOverriden) {
      return body;
    }

    return _originalBody;
  }

  @override
  Future<void> overrideBody(Object? data) async {
    _hasOverriden = true;
    _overrideBody ??= MutableBodyImpl();
    _overrideBody!.replace(await Payload(data).resolve(headers));
  }
}
