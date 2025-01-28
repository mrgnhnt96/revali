import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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

    final (streamBody, close) = switch (response.body) {
      final body? when !body.isNull => (
          body.read(),
          switch (body) {
            BodyData() => body.cleanUp,
            _ => null,
          }
        ),
      _ => (null, null),
    };

    if (streamBody == null) {
      await http.flush();
      await http.close();
      return;
    }

    final socket = await http.detachSocket();

    StreamSubscription<Uint8List>? socketListener;
    socketListener = socket.listen(
      (_) {},
      cancelOnError: true,
      onDone: () {
        socketListener?.cancel().ignore();
        close?.call();
      },
      onError: (e) {
        socketListener?.cancel().ignore();
        close?.call();
      },
    );

    try {
      await for (final event in streamBody) {
        socket
          ..add(utf8.encode(event.length.toRadixString(16)))
          ..add([13, 10]) // CRLF
          ..add(event)
          ..add([13, 10]); // CRLF

        await socket.flush();
      }

      socket.add([48, 13, 10, 13, 10]); // 0 CRLF CRLF
    } catch (e) {
      // ignore
    }

    try {
      socket.close().ignore();
      socketListener.cancel().ignore();
    } catch (_) {
      // ignore
    }

    await http.close();
  }
}
