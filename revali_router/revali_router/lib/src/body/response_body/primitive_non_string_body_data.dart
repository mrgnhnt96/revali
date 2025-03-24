part of 'base_body_data.dart';

final class PrimitiveNonStringBodyData<T> extends BaseBodyData<T> {
  PrimitiveNonStringBodyData(super.data);

  @override
  String get mimeType => 'text/plain';

  @override
  int get contentLength => jsonEncode(data).length;

  @override
  Stream<List<int>> read() {
    return Stream.value(encoding.encode(jsonEncode(data)));
  }

  @override
  ReadOnlyHeaders headers(ReadOnlyHeaders? requestHeaders) {
    return MutableHeadersImpl()
      ..mimeType = mimeType
      ..contentLength = contentLength;
  }
}
