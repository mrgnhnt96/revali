import 'dart:io';

import 'package:revali_router/src/request/parts/response.dart';
import 'package:revali_router/src/request/request_context.dart';

void handleRequests(
  HttpServer server,
  Future<Response> Function(RequestContext context) handler,
) {
  server.listen((request) async {
    try {
      final context = RequestContext.from(request);

      final response = await handler(context);

      response.write(request.response);
    } catch (e) {
      final response = Response.internalServerError();

      response.write(request.response);
    }
  });
}
