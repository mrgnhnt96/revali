import 'package:revali_router_core/body/read_only_body.dart';
import 'package:revali_router_core/headers/read_only_headers.dart';

abstract class ReadOnlyResponseContext {
  const ReadOnlyResponseContext();

  int get statusCode;
  ReadOnlyBody? get body;

  ReadOnlyHeaders get headers;
}
