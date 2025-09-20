import 'package:analyzer/dart/element/element2.dart';
import 'package:revali_server/converters/server_type.dart';

class ServerGenericType {
  const ServerGenericType({required this.name, required this.bound});

  factory ServerGenericType.fromElement(TypeParameterElement element) {
    final name = element.name3;
    final bound = switch (element.bound) {
      final e? => ServerType.fromType(e),
      _ => null,
    };

    if (name == null) {
      throw Exception('Generic type name is null');
    }

    return ServerGenericType(name: name, bound: bound);
  }

  final String name;
  final ServerType? bound;
}
