part of 'base_body_data.dart';

abstract base class JsonData<T> extends BaseBodyData<T> {
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
  Headers headers(Headers? requestHeaders) {
    return HeadersImpl()
      ..mimeType = mimeType
      ..contentLength = contentLength;
  }
}
