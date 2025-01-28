import 'dart:convert';
import 'dart:io' as io;
import 'dart:math';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:meta/meta.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:revali_router/src/headers/mutable_headers_impl.dart';
import 'package:revali_router_core/revali_router_core.dart';

part 'binary_body_data.dart';
part 'byte_stream_body_data.dart';
part 'file_body_data.dart';
part 'form_body_data.dart';
part 'json_body_data.dart';
part 'json_data.dart';
part 'list_body_data.dart';
part 'memory_file_body_data.dart';
part 'null_body_data.dart';
part 'stream_body_data.dart';
part 'string_body_data.dart';
part 'unknown_body_data.dart';

sealed class BaseBodyData<T> extends BodyData {
  BaseBodyData(this.data);

  factory BaseBodyData.from(Object? data) {
    final result = switch (data) {
      BaseBodyData() => data,
      String() => StringBodyData(data),
      Map<String, dynamic>() => JsonBodyData(data),
      Map() => JsonBodyData({
          for (final key in data.keys) '$key': data[key],
        }),
      io.File() => FileBodyData(data),
      MemoryFile() => MemoryFileBodyData(data),
      Binary() => BinaryBodyData(data),
      List() => ListBodyData(data),
      // ignore: prefer_void_to_null
      Null() => NullBodyData(),
      Stream<List<int>>() => ByteStreamBodyData(data),
      Stream<dynamic>() => StreamBodyData(data),
      ReadOnlyBody() => BaseBodyData<dynamic>.from(data.data),
      _ => throw UnsupportedError('Unsupported body data type: $data'),
    };

    return result as BaseBodyData<T>;
  }

  @override
  final T data;

  @override
  bool get isNull => this is NullBodyData;
  bool get isBinary => this is BinaryBodyData;
  bool get isString => this is StringBodyData;
  bool get isJson => this is JsonBodyData;
  bool get isList => this is ListBodyData;
  bool get isFormData => this is FormDataBodyData;
  bool get isUnknown => this is UnknownBodyData;
  bool get isStream => this is StreamBodyData;
  bool get isFile => this is FileBodyData;
  bool get isMemoryFile => this is MemoryFileBodyData;
  bool get isByteStream => this is ByteStreamBodyData;

  NullBodyData get asNull => this as NullBodyData;
  BinaryBodyData get asBinary => this as BinaryBodyData;
  StringBodyData get asString => this as StringBodyData;
  JsonBodyData get asJson => this as JsonBodyData;
  ListBodyData get asList => this as ListBodyData;
  FormDataBodyData get asFormData => this as FormDataBodyData;
  UnknownBodyData get asUnknown => this as UnknownBodyData;
  StreamBodyData<dynamic> get asStream => this as StreamBodyData;
  FileBodyData get asFile => this as FileBodyData;
  MemoryFileBodyData get asMemoryFile => this as MemoryFileBodyData;
  ByteStreamBodyData get asByteStream => this as ByteStreamBodyData;
}
