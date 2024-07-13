abstract class ReadOnlyBody {
  const ReadOnlyBody();

  String? get mimeType;
  int? get contentLength;
  Stream<List<int>>? read();

  bool get isNull;
}
