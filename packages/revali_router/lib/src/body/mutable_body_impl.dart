import 'dart:convert';

import 'package:revali_router/src/body/body_data.dart';
import 'package:revali_router/src/body/mutable_body.dart';
import 'package:revali_router/utils/types.dart';

class MutableBodyImpl implements MutableBody {
  MutableBodyImpl([this._data]);

  factory MutableBodyImpl.from(Object? object) {
    if (object is MutableBodyImpl) {
      return object;
    }

    final bodyData = switch (object) {
      BodyData() => object,
      String() => StringBodyData(object),
      Map<String, dynamic>() => JsonBodyData(object),
      List() => ListBodyData(object),
      null => null,
      Object() => JsonBodyData(jsonDecode(jsonEncode(object))),
    };

    return MutableBodyImpl(bodyData);
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
  bool get isBinary => _data?.isBinary ?? false;

  @override
  bool get isJson => _data?.isJson ?? false;

  @override
  bool get isList => _data?.isList ?? false;

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
  Binary get asBinary {
    return maybeBinary ?? (throw StateError('Body is not a file'));
  }

  @override
  Map<String, dynamic> get asJson {
    return maybeJson ?? (throw StateError('Body is not JSON'));
  }

  @override
  List get asList {
    return maybeList ?? (throw StateError('Body is not a list'));
  }

  @override
  String get asString {
    return maybeString ?? (throw StateError('Body is not a string'));
  }

  @override
  Binary? get maybeBinary {
    if (!isBinary) {
      return null;
    }

    return _data!.asBinary.data;
  }

  @override
  Map<String, dynamic>? get maybeJson {
    if (!isJson) {
      return null;
    }

    return _data!.asJson.data;
  }

  @override
  List? get maybeList {
    if (!isList) {
      return null;
    }

    return _data!.asList.data;
  }

  @override
  String? get maybeString {
    if (!isString) {
      return null;
    }

    return _data!.asString.data;
  }
}
