import 'package:analyzer/dart/constant/value.dart';

class ServerAllowOrigins {
  const ServerAllowOrigins({
    required this.origins,
    required this.inherit,
  });

  factory ServerAllowOrigins.fromDartObject(DartObject object) {
    final raw = object.getField('origins')?.toSetValue() ?? {};
    final inherit = object.getField('inherit')?.toBoolValue() ?? true;

    return ServerAllowOrigins(
      origins: raw.map((e) => e.toStringValue()!).toSet(),
      inherit: inherit,
    );
  }

  final Set<String> origins;
  final bool inherit;
}
