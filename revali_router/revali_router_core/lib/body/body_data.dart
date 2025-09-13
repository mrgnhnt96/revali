import 'dart:convert';

import 'package:revali_router_core/method_mutations/headers/headers.dart';

abstract base class BodyData {
  BodyData();

  /// The mime type of the body.
  ///
  /// e.g. `text/plain`, `application/json`, `application/x-www-form-urlencoded`
  String? get mimeType;

  /// The length of the body in bytes.
  ///
  /// If the length is unknown, this will return `null`.
  int? get contentLength => null;

  /// The encoding of the body.
  ///
  /// By default, this is `utf8`.
  Encoding encoding = utf8;

  /// Reads the body as a stream of bytes.
  ///
  /// If the body has already been read, this will return the same data.
  Stream<List<int>>? read();

  /// Resolves the headers based on the body.
  ///
  /// Some expected headers are:
  /// - `Content-Type`
  /// - `Content-Length`
  /// - `Content-Encoding`
  Headers headers(Headers? requestHeaders);

  dynamic get data;

  bool get isNull;

  @override
  String toString() => '$data';
}
