import 'dart:async';

import 'package:revali_client/revali_client.dart';

class HttpResponse extends StreamView<List<int>> {
  HttpResponse({
    required this.request,
    required this.statusCode,
    required this.persistentConnection,
    required this.reasonPhrase,
    required this.contentLength,
    required this.stream,
    Map<String, String>? headers,
  }) : headers = {...?headers},
       super(stream);

  final HttpRequest request;

  int statusCode;

  Map<String, String> headers;

  bool persistentConnection;

  String? reasonPhrase;

  int? contentLength;

  Stream<List<int>> stream;
}
