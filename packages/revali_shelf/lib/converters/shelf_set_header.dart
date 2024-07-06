import 'package:analyzer/dart/constant/value.dart';

class ShelfSetHeader {
  const ShelfSetHeader({
    required this.name,
    required this.value,
  });

  factory ShelfSetHeader.fromDartObject(DartObject object) {
    final name = object.getField('name')?.toStringValue();
    final value = object.getField('value')?.toStringValue();

    if (name == null || value == null) {
      throw ArgumentError('name and value must be provided');
    }

    return ShelfSetHeader(
      name: name,
      value: value,
    );
  }

  final String name;
  final String value;
}
