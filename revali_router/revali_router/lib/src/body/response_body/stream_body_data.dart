part of 'base_body_data.dart';

final class StreamBodyData extends BaseBodyData<Stream<dynamic>> {
  StreamBodyData(
    super.data, {
    this.contentLength,
    this.filename = 'file.txt',
  });

  @override
  String get mimeType => 'application/octet-stream';

  @override
  final int? contentLength;

  final String filename;

  @override
  Stream<List<int>> read() {
    return switch (data) {
      Stream<String>() => data.transform(utf8.encoder),
      final Stream<List<int>> data => data,
      final Stream<Map<dynamic, dynamic>> data =>
        data.map((e) => utf8.encode(jsonEncode(e))),
      _ => data.map((e) {
          String data;

          try {
            data = jsonEncode(e);
          } catch (_) {
            data = e.toString();
          }

          return utf8.encode(data);
        }),
    };
  }

  @override
  ReadOnlyHeaders headers(ReadOnlyHeaders? requestHeaders) {
    return MutableHeadersImpl()
      ..mimeType = mimeType
      ..filename = filename
      ..contentLength = contentLength;
  }
}
