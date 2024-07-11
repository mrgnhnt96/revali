import 'package:analyzer/dart/constant/value.dart';

class ServerHttpCode {
  const ServerHttpCode(this.code);

  factory ServerHttpCode.fromDartObject(DartObject object) {
    final code = object.getField('code')?.toIntValue();

    if (code == null) {
      throw ArgumentError.value(object, 'object', 'Invalid ServerHttpCode');
    }

    return ServerHttpCode(code);
  }

  final int code;
}
