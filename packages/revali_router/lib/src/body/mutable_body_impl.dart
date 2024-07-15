import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:revali_router/src/headers/mutable_headers_impl.dart';
import 'package:revali_router_core/revali_router_core.dart';

class MutableBodyImpl extends MutableBody {
  MutableBodyImpl([this._data]);

  BodyData? _data;

  @override
  dynamic get data => _data?.data;

  @override
  bool get isNull => _data == null;

  @override
  void operator []=(String key, Object? data) {
    var data = _data;
    if (data == null) {
      data = JsonBodyData({});
    }

    if (data is! BaseBodyData) {
      throw StateError('Cannot set key-value pairs on non-$BaseBodyData body');
    }

    if (!data.isJson) {
      throw StateError('Cannot set key-value pairs on non-JSON body');
    }

    final json = data.asJson;

    json[key] = data;
    _data = json;
  }

  void add(Object? data) {
    var data = _data;
    if (data == null) {
      data = ListBodyData([]);
    }

    if (data is! BaseBodyData) {
      throw StateError('Cannot add to non-$BaseBodyData body');
    }

    if (!data.isList) {
      throw StateError('Cannot add to non-List body');
    }

    final list = data.asList;

    list.add(data);

    _data = list;
  }

  List<List<int>>? _bytes;
  @override
  Stream<List<int>>? read() async* {
    final bytes = this._bytes;
    if (bytes != null) {
      yield* Stream.fromIterable(bytes);
    }

    _bytes = await _data?.read()?.toList();

    if (_bytes == null) {
      return;
    }

    yield* Stream.fromIterable(_bytes!);
  }

  @override
  int? get contentLength => _data?.contentLength;

  @override
  String? get mimeType => _data?.mimeType;

  @override
  void replace(Object? data) async {
    _data = switch (data) {
      BodyData() => data,
      _ => BaseBodyData.from(data),
    };
  }

  @override
  ReadOnlyHeaders headers(ReadOnlyHeaders? requestHeaders) =>
      _data?.headers(requestHeaders) ?? MutableHeadersImpl();
}
