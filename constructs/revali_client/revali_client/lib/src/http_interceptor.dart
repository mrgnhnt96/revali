import 'dart:async';

import 'package:revali_client/src/http_request.dart';
import 'package:revali_client/src/http_response.dart';

abstract interface class HttpInterceptor {
  const HttpInterceptor();

  FutureOr<void> onRequest(HttpRequest request);

  FutureOr<void> onResponse(HttpResponse response);
}
