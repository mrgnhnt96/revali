import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_shelf/converters/shelf_param_with_value.dart';
import 'package:revali_shelf/revali_shelf.dart';

class ShelfExceptionCatcher {
  const ShelfExceptionCatcher({
    required this.className,
    required this.importPath,
    required this.params,
  });

  factory ShelfExceptionCatcher.fromDartObject(DartObject object) {
    final name = object.type?.getDisplayString(withNullability: false);
    final filePath = object.type?.element?.library?.identifier;
    final params = <ShelfParam>[];

    if (object.type case final InterfaceType type) {
      if (type.constructors.isEmpty) {
        throw Exception(
          'Invalid $ExceptionCatcher, At least 1 constructor is needed',
        );
      }

      params.addAll(
        type.constructors.first.parameters.map(ShelfParam.fromElement),
      );
    } else {
      throw Exception('Invalid $ExceptionCatcher, failed to parse');
    }

    if (name == null || filePath == null) {
      throw Exception('Invalid $ExceptionCatcher, failed to parse');
    }

    return ShelfExceptionCatcher(
      className: name,
      importPath: filePath,
      params: params.map((e) => ShelfParamWithValue.fromDartObject(object, e)),
    );
  }

  final String className;
  final String importPath;
  final Iterable<ShelfParamWithValue> params;

  bool get isFileImport => importPath.startsWith('file:');
}
