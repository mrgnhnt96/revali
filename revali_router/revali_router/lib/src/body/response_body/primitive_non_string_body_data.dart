part of 'base_body_data.dart';

final class PrimitiveNonStringBodyData<T> extends BaseBodyData<T> {
  PrimitiveNonStringBodyData(super.data);

  List<int>? _cachedBytes;

  List<int> encodedBytes() {
    return _cachedBytes ??= encoding.encode(jsonEncode(data));
  }

  @override
  String get mimeType => 'text/plain';

  @override
  int get contentLength => encodedBytes().length;

  @override
  Stream<List<int>> read() {
    return Stream.value(encodedBytes());
  }

  @override
  Headers headers(Headers? requestHeaders) {
    return HeadersImpl()
      ..mimeType = mimeType
      ..contentLength = contentLength;
  }
}
