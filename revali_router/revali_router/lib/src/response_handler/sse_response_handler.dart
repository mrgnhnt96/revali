import 'dart:convert';
import 'dart:io';

import 'package:revali_router/revali_router.dart';

class SseResponseHandler with RemoveHeadersMixin implements ResponseHandler {
  const SseResponseHandler();

  @override
  Future<void> handle(
    ReadOnlyResponse response,
    RequestContext context,
    HttpResponse httpResponse,
  ) async {
    final http = httpResponse;

    final responseHeaders = switch (response) {
      MutableResponse() => response.joinedHeaders,
      _ => MutableResponseImpl.from(response).joinedHeaders,
    };

    http.statusCode = response.statusCode;

    switch (response.statusCode) {
      case HttpStatus.notModified:
      case HttpStatus.noContent:
        removeContentRelated(responseHeaders);
      case HttpStatus.notFound:
        removeAccessControl(responseHeaders);
      default:
        break;
    }

    responseHeaders.forEach((key, values) {
      http.headers.set(key, values.join(','));
    });

    final body = switch (response.body) {
      final body? when !body.isNull => body.read(),
      _ => null,
    };

    if (body == null) {
      await http.flush();
      await http.close();
      return;
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
