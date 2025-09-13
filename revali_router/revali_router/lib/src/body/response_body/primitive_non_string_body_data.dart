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
  Headers headers(Headers? requestHeaders) {
    return HeadersImpl()
      ..mimeType = mimeType
      ..contentLength = contentLength;
  }
}
