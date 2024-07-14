import 'dart:convert';
import 'dart:io';

import 'package:mime/mime.dart';
import 'package:revali_router_core/body/read_only_body.dart';
import 'package:revali_router_core/file/memory_file.dart';
import 'package:revali_router_core/utils/types.dart';

abstract class BodyData extends ReadOnlyBody {
  BodyData();

  factory BodyData.from(Object? data) {
    final result = switch (data) {
      BodyData() => data,
      String() => StringBodyData(data),
      Map<String, dynamic>() => JsonBodyData(data),
      Map() => JsonBodyData({
          for (final key in data.keys) '$key': data[key],
        }),
      File() => FileBodyData(data),
      MemoryFile() => MemoryFileBodyData(data),
      Binary() => BinaryBodyData(data),
      List() => ListBodyData(data),
      _ => throw UnsupportedError('Unsupported body data type: $data'),
    };

    return result;
  }

  bool get isBinary => this is BinaryBodyData;
  bool get isString => this is StringBodyData;
  bool get isJson => this is JsonBodyData;
  bool get isList => this is ListBodyData;
  bool get isFormData => this is FormDataBodyData;
  bool get isUnknown => this is UnknownBodyData;
  bool get isNull => false;

  BinaryBodyData get asBinary => this as BinaryBodyData;
  StringBodyData get asString => this as StringBodyData;
  JsonBodyData get asJson => this as JsonBodyData;
  ListBodyData get asList => this as ListBodyData;
  FormDataBodyData get asFormData => this as FormDataBodyData;

  String? get mimeType => null;
  int? get contentLength => null;

  Encoding encoding = utf8;

  Stream<List<int>>? read();
}

sealed class BaseResponseBodyData<T> extends BodyData {
  BaseResponseBodyData(this.data);

  final T data;
}

final class FileBodyData extends BaseResponseBodyData<File> {
  FileBodyData(super.data);

  String? _mimeType;
  @override
  String? get mimeType {
    return _mimeType ??= lookupMimeType(data.path);
  }

  int? _length;
  @override
  int? get contentLength {
    return _length ??= data.lengthSync();
  }

  List<int>? _bytes;
  @override
  Stream<List<int>> read() async* {
    if (_bytes case final bytes?) {
      yield* Stream.fromIterable([bytes]);
    }
    final bytes = _bytes = await data.readAsBytesSync();

    yield* Stream.fromIterable([bytes]);
  }
}

final class MemoryFileBodyData extends BaseResponseBodyData<MemoryFile> {
  MemoryFileBodyData(super.data);

  @override
  String? get mimeType {
    return data.mimeType;
  }

  @override
  int? get contentLength {
    return data.bytes.length;
  }

  @override
  Stream<List<int>> read() {
    return Stream.fromIterable([data.bytes]);
  }
}

final class BinaryBodyData extends BaseResponseBodyData<Binary> {
  BinaryBodyData(
    super.data, {
    this.mimeType = 'application/octet-stream',
  });

  @override
  final String? mimeType;

  @override
  int? get contentLength {
    return data.length;
  }

  @override
  Stream<List<int>> read() {
    return Stream.fromIterable(data);
  }
}

final class UnknownBodyData extends BinaryBodyData {
  UnknownBodyData(super.data, {required this.mimeType});

  @override
  final String? mimeType;
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

  factory JsonBodyData.fromString(String data) {
    return JsonBodyData(jsonDecode(data) as Map<String, dynamic>);
  }

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

final class FormDataBodyData extends JsonBodyData {
  FormDataBodyData(super.data);

  FormDataBodyData.fromString(String data)
      : super(jsonDecode(data) as Map<String, dynamic>);

  @override
  String? get mimeType => 'application/x-www-form-urlencoded';

  @override
  int? get contentLength {
    return data.keys.fold<int>(0, (previousValue, element) {
      return previousValue + element.length + data[element].toString().length;
    });
  }

  @override
  Stream<List<int>> read() {
    final encoded = data.keys.map((key) {
      return '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(data[key].toString())}';
    }).join('&');

    return Stream.value(encoding.encode(encoded));
  }
}
