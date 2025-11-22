import 'package:revali_router_core/revali_router_core.dart';

class WebsocketResponseHandler implements ResponseHandler {
  const WebsocketResponseHandler();

  @override
  Future<void> handle(_, RequestContext context, ___) async {
    await context.close();
  }
}
