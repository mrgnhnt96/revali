import 'package:analyzer/dart/constant/value.dart';
import 'package:revali_shelf/converters/shelf_class.dart';
import 'package:revali_shelf/converters/shelf_param_with_value.dart';

class ShelfExceptionCatcher implements ShelfClass {
  const ShelfExceptionCatcher({
    required this.className,
    required this.importPath,
    required this.params,
    required this.source,
  });

  factory ShelfExceptionCatcher.fromDartObject(
      DartObject object, String source) {
    final shelfClass = ShelfClass.fromDartObject(object, source);

    return ShelfExceptionCatcher(
      className: shelfClass.className,
      importPath: shelfClass.importPath,
      params: shelfClass.params,
      source: source,
    );
  }

  final String className;
  final String importPath;
  final Iterable<ShelfParamWithValue> params;
  final String source;

  bool get isFileImport => importPath.startsWith('file:');
}
