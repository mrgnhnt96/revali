import 'dart:io';

import 'package:revali_router/src/response/simple_response.dart';
import 'package:revali_router_core/response/read_only_response.dart';

class CannedResponse {
  CannedResponse._();

  static ReadOnlyResponse options({
    required Set<String> allowedMethods,
  }) {
    return SimpleResponse(
      200,
      headers: {
        HttpHeaders.allowHeader: allowedMethods.join(', '),
      },
    );
  }

  /// ONLY for web socket **disconnects**
  ///
  /// The expected behavior is that the server will close the connection
  /// without sending any further data (headers, body, etc.)
  ///
  /// This is a special case and should not be used for any other purpose.
  /// Status Code: 1000
  static ReadOnlyResponse webSocket() {
    return SimpleResponse(1000);
  }

  static ReadOnlyResponse redirect(
    String location, {
    int statusCode = 302,
    Map<String, String> headers = const {},
  }) {
    return SimpleResponse(
      statusCode,
      headers: {
        'Location': location,
        ...headers,
      },
    );
  }
}
