import 'package:analyzer/dart/constant/value.dart';

class ServerAllowHeaders {
  const ServerAllowHeaders({required this.headers});

  factory ServerAllowHeaders.fromDartObject(DartObject object) {
    final raw = object.getField('headers')?.toSetValue() ?? {};

    return ServerAllowHeaders(
      headers: raw.map((e) => e.toStringValue()!).toSet(),
    );
  }

  final Set<String> headers;
}
