import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:revali_shelf/converters/shelf_param.dart';
import 'package:revali_shelf/converters/shelf_param_with_value.dart';

interface class ShelfClass {
  const ShelfClass({
    required this.className,
    required this.importPath,
    required this.params,
    required this.source,
  });

  static ShelfClass fromDartObject(DartObject object, String source) {
    final name = object.type?.getDisplayString(withNullability: false);
    final filePath = object.type?.element?.library?.identifier;
    final params = <ShelfParam>[];

    if (object.type case final InterfaceType type) {
      if (type.constructors.isEmpty) {
        throw Exception(
          'Invalid $ShelfClass, At least 1 constructor is needed',
        );
      }

      params.addAll(
        type.constructors.first.parameters.map(ShelfParam.fromElement),
      );
    } else {
      throw Exception('Invalid $ShelfClass, failed to parse');
    }

    if (name == null || filePath == null) {
      throw Exception('Invalid $ShelfClass, failed to parse');
    }

    return ShelfClass(
      className: name,
      importPath: filePath,
      params: params.map((e) => ShelfParamWithValue.fromDartObject(object, e)),
      source: source,
    );
  }

  final String className;
  final String importPath;
  final Iterable<ShelfParamWithValue> params;
  final String source;

  bool get isFileImport => importPath.startsWith('file:');
}
