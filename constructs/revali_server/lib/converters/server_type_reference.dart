import 'package:analyzer/dart/constant/value.dart';
import 'package:revali_server/converters/server_class.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/utils/extract_import.dart';

class ServerTypeReference with ExtractImport {
  ServerTypeReference({
    required this.types,
  });

  factory ServerTypeReference.fromElement(
    DartObject object, {
    required Type superType,
    String key = 'types',
  }) {
    final typesValue = object.getField(key)?.toListValue();

    if (typesValue == null || typesValue.isEmpty) {
      return ServerTypeReference(
        types: const [],
      );
    }

    final types = <ServerClass>[];

    for (final typeValue in typesValue) {
      final type = typeValue.toTypeValue();
      if (type == null) {
        throw ArgumentError('Invalid type');
      }

      types.add(ServerClass.fromType(type, superType: superType));
    }

    return ServerTypeReference(types: types);
  }

  final Iterable<ServerClass> types;

  @override
  List<ExtractImport?> get extractors => [...types];

  @override
  List<ServerImports?> get imports => const [];
}
