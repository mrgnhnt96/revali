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

  ServerExpectHeaders merge(ServerExpectHeaders other) {
    return ServerExpectHeaders(
      headers: {...headers, ...other.headers},
    );
  }

  final Set<String> headers;
}
