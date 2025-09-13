part of 'base_body_data.dart';

final class BinaryBodyData extends BaseBodyData<Binary> {
  BinaryBodyData(
    super.data, {
    this.mimeType = 'application/octet-stream',
  });

  @override
  final String? mimeType;

  @override
  int? get contentLength {
    return data.length;
  }

  @override
  Stream<List<int>> read() {
    return Stream.fromIterable([data]);
  }

  @override
  Headers headers(Headers? requestHeaders) {
    return HeadersImpl()
      ..contentLength = contentLength
      ..mimeType = mimeType;
  }
}
