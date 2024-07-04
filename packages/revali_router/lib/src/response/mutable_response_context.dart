import 'package:revali_router/src/response/restricted_mutable_response_context.dart';

abstract class MutableResponseContext
    implements RestrictedMutableResponseContext {
  const MutableResponseContext();

  int get statusCode;
  void set statusCode(int value);

  Map<String, dynamic>? get body;

  /// The value to be set as the body of the response
  ///
  /// The body will be nested under the `data` key in the response
  void set body(Object? value);
}
