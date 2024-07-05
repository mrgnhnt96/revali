import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:revali_shelf/revali_shelf.dart';

class ShelfParamWithValue {
  const ShelfParamWithValue({
    required this.param,
    required this.value,
  });

  factory ShelfParamWithValue.fromDartObject(
      DartObject object, ShelfParam param) {
    final value = object.getField(param.name);

    if (value == null || value is! DartObjectImpl) {
      throw Exception(
        'Invalid $ShelfParamWithValue, failed to parse field: ${param.name}',
      );
    }

    return ShelfParamWithValue(
      param: param,
      value: value.state.toString(),
    );
  }

  final ShelfParam param;
  final String value;
}
