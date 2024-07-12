import 'dart:convert';
import 'dart:io';

import 'package:revali_router/src/body/body_data.dart';
import 'package:revali_router/src/body/mutable_body.dart';

class MutableBodyImpl implements MutableBody {
  MutableBodyImpl([this._data]);

  factory MutableBodyImpl.from(Object? object) {
    final bodyData = switch (object) {
      String() => StringBodyData(object),
      Map<String, dynamic>() => JsonBodyData(object),
      List() => ListBodyData(object),
      null => null,
      Object() => JsonBodyData(jsonDecode(jsonEncode(object))),
    };
    return MutableBodyImpl(bodyData);
  }

  factory MutableBodyImpl.fromPayload(String payload) {
    final attempts = [
      (String data) => MutableBodyImpl.from(jsonDecode(data)),
      (String data) => MutableBodyImpl.from(data),
    ];

    for (final attempt in attempts) {
      try {
        return attempt(payload);
      } catch (_) {
        continue;
      }
    }

    throw ArgumentError('Could not parse body');
  }

  BodyData? _data;

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

    _bytes = await _data?.read().toList();

    yield* Stream.fromIterable(_bytes!);
  }

  @override
  int? get contentLength => _data?.contentLength;

  @override
  bool get isFile => _data?.isFile ?? false;

  @override
  bool get isJson => _data?.isJson ?? false;

  @override
  bool get isString => _data?.isString ?? false;

  @override
  bool get isNull => _data == null;

  @override
  String? get mimeType => _data?.mimeType;

  @override
  void replace(Object? data) {
    _data = MutableBodyImpl.from(data)._data;
  }

  @override
  File get asFile {
    if (!isFile) {
      throw StateError('Body is not a file');
    }

    return _data!.asFile.data;
  }

  @override
  Map<String, dynamic> get asJson {
    if (!isJson) {
      throw StateError('Body is not JSON');
    }

    return _data!.asJson.data;
  }

  @override
  List get asList {
    if (!isJson) {
      throw StateError('Body is not a list');
    }

    return _data!.asList.data;
  }

  @override
  String get asString {
    if (!isString) {
      throw StateError('Body is not a string');
    }

    return _data!.asString.data;
  }
}
