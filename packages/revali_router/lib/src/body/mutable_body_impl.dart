import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:revali_router/src/headers/mutable_headers_impl.dart';
import 'package:revali_router_core/revali_router_core.dart';

class MutableBodyImpl extends MutableBody {
  MutableBodyImpl([this.__data]);

  BodyData? __data;
  BodyData? get _data => __data;
  set _data(BodyData? value) {
    __data = value;
    _bytes = null;
  }

  @override
  dynamic get data => _data?.data;

  @override
  bool get isNull => _data == null;

  @override
  void operator []=(String key, Object? data) {
    var newData = _data;
    if (newData == null || newData.isNull) {
      newData = JsonBodyData({});
    }

    if (newData is! BaseBodyData) {
      throw StateError('Cannot set key-value pairs on non-$BaseBodyData body');
    }

    if (!newData.isJson) {
      throw StateError('Cannot set key-value pairs on non-JSON body');
    }

    final json = newData.asJson;

    json[key] = data;
    _data = json;
  }

  @override
  void add(Object? data) {
    var newData = _data;
    newData ??= ListBodyData([]);

    if (newData is! BaseBodyData) {
      throw StateError('Cannot add to non-$BaseBodyData body');
    }

    if (!newData.isList) {
      throw StateError('Cannot add to non-List body');
    }

    _data = newData.asList..add(data);
  }

  List<List<int>>? _bytes;
  @override
  Stream<List<int>>? read() async* {
    final bytes = _bytes;
    if (bytes != null) {
      yield* Stream.fromIterable(bytes);
      return;
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
  Future<void> replace(Object? data) async {
    _data = switch (data) {
      BodyData() => data,
      _ => BaseBodyData<dynamic>.from(data),
    };
  }

  @override
  ReadOnlyHeaders headers(ReadOnlyHeaders? requestHeaders) =>
      _data?.headers(requestHeaders) ?? MutableHeadersImpl();
}
