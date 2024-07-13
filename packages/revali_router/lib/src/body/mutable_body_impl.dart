import 'package:revali_router/src/body/body_data.dart';
import 'package:revali_router/src/body/mutable_body.dart';

class MutableBodyImpl extends MutableBody {
  MutableBodyImpl([this._data]);

  BodyData? _data;

  @override
  bool get isNull => _data == null;

  @override
  void operator []=(String key, Object? data) {
    var data = _data;
    if (data == null) {
      data = JsonBodyData({});
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
  void replace(Object? data) {
    _data = BodyData.from(data);
  }
}
