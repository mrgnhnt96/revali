part of 'base_body_data.dart';

final class UnknownBodyData extends BinaryBodyData {
  UnknownBodyData(super.data, {required this.mimeType});

  @override
  final String? mimeType;
}

final class StringBodyData extends BaseBodyData<String> {
  StringBodyData(super.data);

  @override
  String get mimeType => 'text/plain';

  @override
  int get contentLength => data.length;

  @override
  Stream<List<int>> read() {
    return Stream.value(encoding.encode(data));
  }

  @override
  ReadOnlyHeaders headers(ReadOnlyHeaders? requestHeaders) {
    final headers = MutableHeadersImpl();

    headers[HttpHeaders.contentTypeHeader] = mimeType;
    headers[HttpHeaders.contentLengthHeader] = '$contentLength';

    return headers;
  }
}
