import 'package:revali_router/src/response/simple_response.dart';
import 'package:revali_router_core/response/read_only_response.dart';
import 'package:revali_router_core/revali_router_core.dart';

class CannedResponse {
  CannedResponse._();

  /// ONLY for web socket **disconnects**
  ///
  /// The expected behavior is that the server will close the connection
  /// without sending any further data (headers, body, etc.)
  ///
  /// This is a special case and should not be used for any other purpose.
  /// Status Code: 1000
  static ReadOnlyResponse webSocket({
    required int statusCode,
    required String reason,
  }) {
    return SimpleResponse(statusCode, body: reason);
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
