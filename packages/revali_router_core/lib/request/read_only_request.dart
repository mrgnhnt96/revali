import 'package:revali_router_core/body/read_only_body.dart';
import 'package:revali_router_core/headers/read_only_headers.dart';

abstract class ReadOnlyRequest {
  const ReadOnlyRequest();

  Future<void> resolvePayload();

  ReadOnlyHeaders get headers;

  ReadOnlyBody get body;

  String get originalPayload;

  Map<String, String> get queryParameters;

  Map<String, Iterable<String>> get queryParametersAll;

  Map<String, String> get pathParameters;

  // This will be implemented in the future
  // ignore: unused_element
  Map<String, Iterable<String>> get _wildcardParameters;

  String get method;

  Uri get uri;

  Iterable<String> get segments;
}
