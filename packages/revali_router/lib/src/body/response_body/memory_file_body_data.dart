part of 'base_body_data.dart';

final class MemoryFileBodyData extends BaseBodyData<MemoryFile> {
  MemoryFileBodyData(super.data);

  @override
  String get mimeType {
    return data.mimeType;
  }

  @override
  int get contentLength {
    return data.bytes.length;
  }

  @override
  Stream<List<int>> read() {
    return Stream.fromIterable([data.bytes]);
  }

  @override
  ReadOnlyHeaders headers(ReadOnlyHeaders? requestHeaders) {
    final headers = MutableHeadersImpl();

    headers[HttpHeaders.contentTypeHeader] = mimeType;
    headers[HttpHeaders.contentLengthHeader] = '$contentLength';
    headers[HttpHeaders.contentDisposition] =
        'attachment; filename="${data.filename}"';

    return headers;
  }
}
