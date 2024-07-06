import 'package:analyzer/dart/constant/value.dart';

class ShelfHttpCode {
  const ShelfHttpCode(this.code);

  factory ShelfHttpCode.fromDartObject(DartObject object) {
    final code = object.getField('code')?.toIntValue();

    if (code == null) {
      throw ArgumentError.value(object, 'object', 'Invalid ShelfHttpCode');
    }

    return ShelfHttpCode(code);
  }

  final int code;
}
