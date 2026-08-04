import 'package:revali_core/revali_core.dart';

class WebsocketResponseHandler implements ResponseHandler {
  const WebsocketResponseHandler();

  @override
  Future<void> handle(_, RequestContext context, ___) async {
    await context.close();
  }
}
