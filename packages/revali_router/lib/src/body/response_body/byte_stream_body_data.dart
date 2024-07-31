part of 'base_body_data.dart';

final class ByteStreamBodyData extends BaseBodyData<Stream<List<int>>> {
  ByteStreamBodyData(
    super.data, {
    required this.contentLength,
    this.filename = 'file.txt',
  });

  @override
  String get mimeType => 'application/octet-stream';

  @override
  final int contentLength;

  final String filename;

  @override
  Stream<List<int>> read() => data.cast();

  @override
  ReadOnlyHeaders headers(ReadOnlyHeaders? requestHeaders) {
    final headers = MutableHeadersImpl();

    headers[HttpHeaders.contentTypeHeader] = mimeType;
    if (contentLength > 0) {
      headers[HttpHeaders.contentLengthHeader] = '$contentLength';
    }
    headers[HttpHeaders.contentDisposition] =
        'attachment; filename="$filename"';

    return headers;
  }
}
