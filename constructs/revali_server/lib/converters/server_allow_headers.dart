import 'package:analyzer/dart/constant/value.dart';

class ServerAllowHeaders {
  const ServerAllowHeaders({
    required this.headers,
    required this.inherit,
  });

  factory ServerAllowHeaders.fromDartObject(DartObject object) {
    final raw = object.getField('headers')?.toSetValue() ?? {};
    final inherit = object.getField('inherit')?.toBoolValue() ?? true;

    return ServerAllowHeaders(
      headers: raw.map((e) => e.toStringValue()!).toSet(),
      inherit: inherit,
    );
  }

  final Set<String> headers;
  final bool inherit;
}
