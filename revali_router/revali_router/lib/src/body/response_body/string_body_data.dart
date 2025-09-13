part of 'base_body_data.dart';

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
  Headers headers(Headers? requestHeaders) {
    return HeadersImpl()
      ..mimeType = mimeType
      ..contentLength = contentLength;
  }
}
