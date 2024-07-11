import 'dart:io';

import 'package:revali_router/src/request/parts/response.dart';

class WebSocketStopResponse extends Response {
  WebSocketStopResponse() : super(0);

  @override
  void write(HttpResponse httpResponse) {
    // Do nothing
  }
}
