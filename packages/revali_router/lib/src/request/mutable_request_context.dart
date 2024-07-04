import 'package:revali_router/src/request/read_only_request_context.dart';

abstract class MutableRequestContext implements ReadOnlyRequestContext {
  const MutableRequestContext();

  void setHeader(String key, String value);

  void removeHeader(String key);
}
