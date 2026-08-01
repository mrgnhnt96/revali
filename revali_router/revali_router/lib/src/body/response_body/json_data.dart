part of 'base_body_data.dart';

abstract base class JsonData<T> extends BaseBodyData<T> {
  JsonData(super.data);

  String? _cached;
  List<int>? _cachedBytes;

  void _clearCache() {
    _cached = null;
    _cachedBytes = null;
  }

  String toJson() {
    return _cached ??= jsonEncode(data);
  }

  List<int> encodedBytes() {
    return _cachedBytes ??= encoding.encode(toJson());
  }

  @override
  String get mimeType => 'application/json';

  @override
  int get contentLength => encodedBytes().length;

  @override
  Headers headers(Headers? requestHeaders) {
    return HeadersImpl()
      ..mimeType = mimeType
      ..contentLength = contentLength;
  }
}
