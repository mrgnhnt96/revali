import 'dart:io';

import 'package:revali_router/src/request/request_context_impl.dart';
import 'package:revali_router/src/response/simple_response.dart';
import 'package:revali_router/utils/http_response_extensions.dart';
import 'package:revali_router_core/request/request_context.dart';
import 'package:revali_router_core/response/read_only_response.dart';

void handleRequests(
  HttpServer server,
  Future<ReadOnlyResponse> Function(RequestContext context) handler,
) {
  try {
    server.listen(
      (request) async {
        try {
          final context = await RequestContextImpl.fromRequest(request);

          final response = await handler(context);

          request.response.send(response, requestMethod: context.method);
        } catch (e) {
          print('Failed to handle request: $e');
          request.response.send(
            SimpleResponse(
              500,
              body: 'Internal Server Error (ROOT)',
            ),
          );
        }
      },
      onError: (e) {
        print('Failed to handle request: $e');
      },
    );
  } catch (e) {
    print('Failed to start server: $e');
  }
}
