part of 'base_body_data.dart';

abstract class JsonData<T> extends BaseBodyData<T> {
  JsonData(super.data);

  String? _cached;
  void _clearCache() {
    _cached = null;
  }

  String toJson() {
    return _cached ??= jsonEncode(data);
  }

  @override
  String get mimeType => 'application/json';

  @override
  int get contentLength => toJson().length;

  @override
  ReadOnlyHeaders headers(ReadOnlyHeaders? requestHeaders) {
    final headers = MutableHeadersImpl();

    headers[HttpHeaders.contentTypeHeader] = mimeType;
    headers[HttpHeaders.contentLengthHeader] = '$contentLength';

    return headers;
  }
}
