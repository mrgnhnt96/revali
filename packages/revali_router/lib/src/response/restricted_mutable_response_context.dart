import 'package:revali_router/src/response/read_only_response_context.dart';

abstract class RestrictedMutableResponseContext
    implements ReadOnlyResponseContext {
  const RestrictedMutableResponseContext();

  void setHeader(String key, String value);

  void removeHeader(String key);

  /// The value to be set as the body of the response
  ///
  /// The key CANNOT be `data` as it is reserved for the body
  void addToBody(String key, Object value);
}
