import 'dart:io';

import 'package:revali_router/src/request/request_context_impl.dart';
import 'package:revali_router/src/response/canned_response.dart';
import 'package:revali_router/src/response/read_only_response_context.dart';
import 'package:revali_router/utils/http_response_extensions.dart';

void handleRequests(
  HttpServer server,
  Future<ReadOnlyResponseContext> Function(RequestContextImpl context) handler,
) {
  server.listen((request) async {
    try {
      final context = await RequestContextImpl.fromRequest(request);

      final response = await handler(context);

      request.response.send(response);
    } catch (e) {
      final response = CannedResponse.internalServerError();

      request.response.send(response);
    }
  });
}
