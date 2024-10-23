// ignore_for_file: avoid_setters_without_getters

import 'dart:convert';

import 'package:http_parser/http_parser.dart';
import 'package:revali_router_core/headers/read_only_headers.dart';

abstract class MutableHeaders implements ReadOnlyHeaders {
  void set(String key, String value);
  void add(String key, String value);

  /// Removed the header with case-insensitive name [key].
  void remove(String key);

  void operator []=(String key, String value);

  void addAll(Map<String, String> headers);

  void addEverything(Map<String, Iterable<String>> headers);

  void clear();

  set mimeType(String? value);
  set contentLength(int? value);
  set origin(String? value);
  set range((int, int)? value);
  set ifModifiedSince(DateTime? value);
  set encoding(Encoding value);
  set contentType(MediaType? value);
  set contentTypeString(String? value);
  set transferEncoding(String? value);
  set filename(String? value);
  set acceptRanges(String? value);
  set lastModified(DateTime? value);
}
