import 'package:revali_router_core/body/read_only_body.dart';
import 'package:revali_router_core/headers/read_only_headers.dart';

abstract class ReadOnlyRequestContext {
  const ReadOnlyRequestContext();

  Future<void> resolvePayload();

  ReadOnlyHeaders get headers;

  ReadOnlyBody get body;

  Map<String, String> get queryParameters;

  Map<String, List<String>> get queryParametersAll;

  Map<String, String> get pathParameters;

  // This will be implemented in the future
  // ignore: unused_element
  Map<String, List<String>> get _wildcardParameters;
}