part of 'base_body_data.dart';

final class ByteStreamBodyData extends BaseBodyData<Stream<List<int>>> {
  ByteStreamBodyData(
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
  Stream<List<int>> read() => data.cast();

  @override
  ReadOnlyHeaders headers(ReadOnlyHeaders? requestHeaders) {
    return MutableHeadersImpl()
      ..mimeType = mimeType
      ..filename = filename
      ..contentLength = contentLength;
  }
}