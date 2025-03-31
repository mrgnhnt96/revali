import 'dart:convert';

import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:revali_router/src/headers/mutable_headers_impl.dart';
import 'package:revali_router_core/revali_router_core.dart';

base class MutableBodyImpl extends MutableBody {
  MutableBodyImpl([this.__data]);

  BodyData? __data;
  BodyData? get _data => __data;
  set _data(BodyData? value) {
    __data = value;
    _byteStream = null;
  }

  @override
  dynamic get data => _data?.data;

  @override
  bool get isNull => _data is NullBodyData || _data == null;

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

  Stream<List<int>>? _byteStream;
  @override
  Stream<List<int>>? read() async* {
    final bytes = _byteStream;
    if (bytes != null) {
      yield* bytes;
      return;
    }

    final stream = _byteStream = _data?.read()?.asBroadcastStream();

    if (stream == null) {
      return;
    }

    yield* stream;
  }

  @override
  int? get contentLength => _data?.contentLength;

  @override
  String? get mimeType => _data?.mimeType;

  @override
  Future<void> replace(Object? data) async {
    _data = switch (data) {
      BodyData() => data,
      _ => () {
          try {
            return BaseBodyData<dynamic>.from(data);
          } catch (_) {
            return BaseBodyData<dynamic>.from(jsonDecode(jsonEncode(data)));
          }
        }()
    };
  }

  @override
  ReadOnlyHeaders headers(ReadOnlyHeaders? requestHeaders) =>
      _data?.headers(requestHeaders) ?? MutableHeadersImpl();
}
