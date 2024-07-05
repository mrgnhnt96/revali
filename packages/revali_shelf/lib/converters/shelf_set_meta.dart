import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/src/dart/element/type.dart';

class ShelfSetMeta {
  const ShelfSetMeta({
    required this.typeArg,
    required this.value,
    required this.typeImport,
  });

  static ShelfSetMeta fromDartObject(DartObject object, String source) {
    final objectType = object.type;
    if (objectType is! InterfaceTypeImpl) {
      throw ArgumentError('Expected an InterfaceTypeImpl');
    }
    final type =
        objectType.typeArguments.first.getDisplayString(withNullability: true);

    final typeImport = objectType.element.librarySource.uri.toString();

    // get the type argument of the SetMeta class
    return ShelfSetMeta(
      typeArg: type,
      typeImport: typeImport,
      // TODO: GET THE TYPE!!
      value: '',
    );
  }

  final String typeArg;
  final String typeImport;
  final String value;
}
