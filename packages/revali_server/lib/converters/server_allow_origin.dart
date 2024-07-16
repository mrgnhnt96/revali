import 'package:analyzer/dart/constant/value.dart';

class ServerAllowOrigin {
  const ServerAllowOrigin({required this.origins});

  factory ServerAllowOrigin.fromDartObject(DartObject object) {
    final raw = object.getField('origins')?.toSetValue() ?? {};

    return ServerAllowOrigin(
      origins: raw.map((e) => e.toStringValue()!).toSet(),
    );
  }

  final Set<String> origins;
}
