import 'dart:convert';

abstract interface class ReadOnlyPayload {
  const ReadOnlyPayload();

  int? get contentLength;
  Stream<List<int>> read();
  String readAsString({Encoding encoding = utf8});
}
