// ignore_for_file: avoid_print

import 'dart:io';

import 'package:revali_router/src/request/request_context_impl.dart';
import 'package:revali_router/src/response/simple_response.dart';
import 'package:revali_router/utils/http_response_extensions.dart';
import 'package:revali_router_core/request/request_context.dart';
import 'package:revali_router_core/response/read_only_response.dart';
import 'package:revali_router_core/response_handler/response_handler.dart';

Future<void> handleRequests(
  HttpServer server,
  Future<ReadOnlyResponse> Function(RequestContext context) handler,
  Future<ResponseHandler> Function(RequestContext context) responseHandler,
) async {
  try {
    await for (final request in server) {
      print('${request.uri}');
      ReadOnlyResponse response;
      RequestContext context;
      try {
        context = RequestContextImpl.fromRequest(request);

        response = await handler(context);
      } catch (e) {
        print('Failed to handle request: $e');
        await request.response.send(
          SimpleResponse(
            500,
            body: 'Internal Server Error (ROOT)',
          ),
        );

        continue;
      }

      try {
        final handler = await responseHandler(context);

        await handler.handle(response, context, request.response);
      } catch (e) {
        print('Failed to send response: $e');
      }
    }
  } catch (e) {
    print('Failed to start server: $e');
  }
}
