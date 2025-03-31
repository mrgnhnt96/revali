import 'package:revali_router_core/request/request_context.dart';
import 'package:revali_router_core/response_handler/response_handler.dart';

class WebsocketResponseHandler implements ResponseHandler {
  const WebsocketResponseHandler();

  @override
  Future<void> handle(_, RequestContext context, ___) async {
    await context.close();
  }
}
