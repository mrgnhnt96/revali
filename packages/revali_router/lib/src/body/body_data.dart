import 'dart:convert';
import 'dart:io';

import 'package:mime/mime.dart';

sealed class BodyData {
  BodyData();

  bool get isFile => this is FileBodyData;
  bool get isString => this is StringBodyData;
  bool get isJson => this is JsonBodyData;
  bool get isList => this is ListBodyData;

  FileBodyData get asFile => this as FileBodyData;
  StringBodyData get asString => this as StringBodyData;
  JsonBodyData get asJson => this as JsonBodyData;
  ListBodyData get asList => this as ListBodyData;

  String? get mimeType => null;
  int? get contentLength => null;

  Encoding encoding = utf8;

  Stream<List<int>> read();
}

sealed class BaseResponseBodyData<T> extends BodyData {
  BaseResponseBodyData(this.data);

  final T data;
}

final class FileBodyData extends BaseResponseBodyData<File> {
  FileBodyData(super.data);

  @override
  String? get mimeType {
    if (!data.existsSync()) return null;

    final mimeType = lookupMimeType(data.path);

    return mimeType ?? 'application/octet-stream';
  }

  @override
  int? get contentLength {
    if (!data.existsSync()) return null;

    return data.lengthSync();
  }

  @override
  Stream<List<int>> read() {
    return data.openRead();
  }
}

final class StringBodyData extends BaseResponseBodyData<String> {
  StringBodyData(super.data);

  @override
  String? get mimeType => 'text/plain';

  @override
  int? get contentLength => data.length;

  @override
  Stream<List<int>> read() {
    return Stream.value(encoding.encode(data));
  }
}

abstract class JsonData<T> extends BaseResponseBodyData<T> {
  JsonData(super.data);

  String? _cached;
  void _clearCache() {
    _cached = null;
  }

  String toJson() {
    return _cached ??= jsonEncode(data);
  }

  @override
  String? get mimeType => 'application/json';

  @override
  int? get contentLength => toJson().length;
}

final class JsonBodyData extends JsonData<Map<String, dynamic>> {
  JsonBodyData(super.data);

  void operator []=(String key, Object? value) {
    data[key] = value;
    _clearCache();
  }

  @override
  Stream<List<int>> read() {
    return Stream.value(encoding.encode(toJson()));
  }
}

final class ListBodyData extends JsonData<List<dynamic>> {
  ListBodyData(super.data);

  void add(Object? value) {
    data.add(value);
    _clearCache();
  }

  @override
  Stream<List<int>> read() {
    return Stream.value(encoding.encode(toJson()));
  }
}
