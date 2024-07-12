import 'package:revali_router/src/body/read_only_body.dart';
import 'package:revali_router/src/headers/read_only_headers.dart';

abstract class MutableHeaders implements ReadOnlyHeaders {
  void set(String key, String value);

  /// Removed the header with case-insensitive name [key].
  void remove(String key);

  void operator []=(String key, String value);

  void addAll(Map<String, String> headers);

  void reactToBody(ReadOnlyBody body);
  void reactToStatusCode(int code);
}
