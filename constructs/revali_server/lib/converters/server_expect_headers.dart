import 'package:analyzer/dart/constant/value.dart';

class ServerExpectHeaders {
  const ServerExpectHeaders({
    required this.headers,
  });

  factory ServerExpectHeaders.fromDartObject(DartObject object) {
    final raw = object.getField('headers')?.toSetValue() ?? {};

    return ServerExpectHeaders(
      headers: raw.map((e) => e.toStringValue()!).toSet(),
    );
  }

  final Set<String> headers;
}
