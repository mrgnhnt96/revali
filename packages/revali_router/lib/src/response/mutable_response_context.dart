import 'package:revali_router/src/response/restricted_mutable_response_context.dart';

abstract class MutableResponseContext
    implements RestrictedMutableResponseContext {
  const MutableResponseContext();

  int get statusCode;
  void set statusCode(int value);
}
