import 'package:analyzer/dart/element/element.dart';
import 'package:revali_server/converters/server_type.dart';

class ServerGenericType {
  const ServerGenericType({
    required this.name,
    required this.bound,
  });

  factory ServerGenericType.fromElement(TypeParameterElement element) {
    final name = element.name;
    final bound = switch (element.bound) {
      final e? => ServerType.fromType(e),
      _ => null,
    };

    return ServerGenericType(name: name, bound: bound);
  }

  final String name;
  final ServerType? bound;
}
