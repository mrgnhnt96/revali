// ignore_for_file: avoid_print

import 'dart:io';

import 'package:revali_router/src/request/request_context_impl.dart';
import 'package:revali_router/src/response/simple_response.dart';
import 'package:revali_router_core/request/request_context.dart';
import 'package:revali_router_core/response/read_only_response.dart';
import 'package:revali_router_core/response_handler/response_handler.dart';

Future<void> handleRequests(
  HttpServer server,
  Future<ReadOnlyResponse> Function(RequestContext context) handler,
  Future<ResponseHandler> Function(RequestContext context) responseHandler,
  void Function() close,
) async {
  try {
    await for (final request in server) {
      final context = RequestContextImpl.fromRequest(request);
      ResponseHandler responseSender;

      try {
        responseSender = await responseHandler(context);
      } catch (e) {
        print('Failed to get handler: $e');
        continue;
      }

      handler(context).then((response) {
        responseSender.handle(
          response,
          context,
          request.response,
        );
      }).catchError((e) {
        responseSender
            .handle(
          SimpleResponse(500, body: 'Internal Server Error (ROOT)'),
          context,
          request.response,
        )
            .catchError((Object e) {
          print('Failed to send response');
          print(e);
        });
      }).ignore();
    }

    close();
  } catch (e) {
    print(e);
  }
}
