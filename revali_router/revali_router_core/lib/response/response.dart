import 'package:revali_router_core/body/body.dart';
import 'package:revali_router_core/method_mutations/headers/headers.dart';

abstract class Response {
  const Response();

  Headers get headers;
  set headers(Headers value);

  int get statusCode;
  set statusCode(int value);

  Body get body;
  set body(Object? data);

  /// The headers from the body, if any, joined with the headers
  /// from the response
  Headers get joinedHeaders;
}
