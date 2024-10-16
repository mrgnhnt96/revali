import 'package:analyzer/dart/constant/value.dart';

class ServerStatusCode {
  const ServerStatusCode(this.code);

  factory ServerStatusCode.fromDartObject(DartObject object) {
    final code = object.getField('code')?.toIntValue();

    if (code == null) {
      throw ArgumentError.value(object, 'object', 'Invalid ServerStatusCode');
    }

    return ServerStatusCode(code);
  }

  final int code;
}
