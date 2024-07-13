abstract class ReadOnlyBody {
  const ReadOnlyBody();

  dynamic get data;

  String? get mimeType;
  int? get contentLength;
  Stream<List<int>>? read();

  bool get isNull;
}
