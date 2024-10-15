// ignore_for_file: unused_field

import 'dart:convert';

import 'package:revali_router/revali_router.dart';

base class MyBodyData extends BodyData {
  MyBodyData(
    this._bytes,
    this._encoding,
    this._headers,
  );

  final Stream<List<int>> _bytes;
  final Encoding _encoding;
  final ReadOnlyHeaders _headers;

  @override
  Stream<List<int>> get data => _bytes;

  @override
  ReadOnlyHeaders headers(ReadOnlyHeaders? requestHeaders) {
    return requestHeaders ?? EmptyHeaders();
  }

  @override
  bool get isNull => false;

  @override
  Stream<List<int>>? read() {
    throw UnimplementedError();
  }

  @override
  String? get mimeType => 'binary/octet-stream';
}
