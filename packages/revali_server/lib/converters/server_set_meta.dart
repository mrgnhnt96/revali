import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';

class ServerSetMeta {
  const ServerSetMeta({
    required this.typeArg,
    required this.value,
    required this.imports,
  });

  static ServerSetMeta fromDartObject(
    DartObject object,
    ElementAnnotation annotation,
  ) {
    final objectType = object.type;
    if (objectType is! InterfaceTypeImpl) {
      throw ArgumentError('Expected an InterfaceTypeImpl');
    }
    final type =
        objectType.typeArguments.first.getDisplayString(withNullability: true);

    final imports = <String>{};
    final typeImport = objectType.element.librarySource.uri.toString();
    imports.add(typeImport);

    // get the type argument of the SetMeta class
    return ServerSetMeta(
      typeArg: type,
      imports: imports,
      // TODO: GET THE TYPE!!
      value: '',
    );
  }

  final String typeArg;
  final Iterable<String> imports;
  final String value;
}
