import 'package:revali_router/src/body/read_only_body.dart';
import 'package:revali_router/src/headers/read_only_headers.dart';

abstract class ReadOnlyResponseContext {
  const ReadOnlyResponseContext();

  int get statusCode;
  ReadOnlyBody? get body;

  ReadOnlyHeaders get headers;
}
