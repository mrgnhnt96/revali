abstract class ReadOnlyRequestContext {
  const ReadOnlyRequestContext();

  Map<String, String> get headers;

  Future<String?> get body;

  Map<String, String> get queryParameters;

  Map<String, List<String>> get queryParametersAll;

  Map<String, String> get pathParameters;

  // This will be implemented in the future
  // ignore: unused_element
  Map<String, List<String>> get _wildcardParameters;
}
