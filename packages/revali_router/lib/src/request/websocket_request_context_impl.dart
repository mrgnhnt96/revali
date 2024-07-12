import 'package:revali_router/revali_router.dart';
import 'package:revali_router/src/body/mutable_body.dart';
import 'package:revali_router/src/body/mutable_body_impl.dart';
import 'package:revali_router/src/body/read_only_body.dart';
import 'package:revali_router/src/request/web_socket_request_context.dart';

class WebSocketRequestContextImpl extends MutableRequestContextImpl
    implements WebSocketRequestContext {
  WebSocketRequestContextImpl.fromRequest(super.request)
      : _body = MutableBodyImpl.from(request),
        super.fromRequest();

  late final MutableBody _body;
  @override
  ReadOnlyBody get body {
    return _body;
  }

  @override
  Future<void> overrideBody(Object? data) async {
    _body.replace(await Payload(data, headers.encoding).readAsString());
  }
}
