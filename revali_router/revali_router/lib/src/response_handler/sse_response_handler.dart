import 'dart:convert';
import 'dart:io';

import 'package:revali_router/revali_router.dart';

class SseResponseHandler implements ResponseHandler {
  const SseResponseHandler();

  @override
  Future<void> handle(
    ReadOnlyResponse response,
    RequestContext context,
    HttpResponse httpResponse,
  ) async {
    final http = httpResponse;

    // TODO(mrgnhnt): Prepare headers

    final body = switch (response.body) {
      final body? when !body.isNull => body.read(),
      _ => null,
    };

    if (body == null) {
      // TODO(mrgnhnt): return error
      throw '';
    }

    final socket = await http.detachSocket();

    try {
      await for (final event in body) {
        socket
          ..add(utf8.encode(event.length.toRadixString(16)))
          ..add([13, 10]) // CRLF
          ..add(event)
          ..add([13, 10]); // CRLF
        await socket.flush();
      }

      socket.add([48, 13, 10, 13, 10]); // 0 CRLF CRLF
      await socket.close();
    } catch (e) {
      await socket.close();
    }
  }
}
