import 'dart:async';

import 'package:revali_client/revali_client.dart';

class HttpResponse extends StreamView<List<int>> {
  HttpResponse({
    required this.request,
    required this.statusCode,
    required this.headers,
    required this.persistentConnection,
    required this.reasonPhrase,
    required this.contentLength,
    required this.stream,
  }) : super(stream);

  final HttpRequest request;

  final int statusCode;

  final Map<String, String> headers;

  final bool persistentConnection;

  final String? reasonPhrase;

  final int? contentLength;

  final Stream<List<int>> stream;
}
