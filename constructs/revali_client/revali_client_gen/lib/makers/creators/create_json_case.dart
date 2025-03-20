import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/models/client_type.dart';

Expression createJsonCase(ClientType type) {
  Expression data(ClientType type) {
    return declareFinal(
      'data',
      type: switch (type) {
        ClientType(isIterable: true) => refer('List<dynamic>'),
        ClientType(isPrimitive: true) => refer(type.name),
        // named record
        ClientType(isRecord: true, recordProps: final props?)
            when props.isNotEmpty && props.first.isNamed =>
          refer('Map<dynamic, dynamic>'),
        // at least 1 positional record
        ClientType(isRecord: true) => refer('List<dynamic>'),
        _ => refer('Map<dynamic, dynamic>'),
      },
    );
  }

  if (type.isFuture) {
    if (type.typeArguments.length != 1) {
      throw Exception('Future must have exactly one type argument');
    }

    final typeArgument = type.typeArguments.first;

    return createJsonCase(typeArgument);
  }

  final result = data(type);
  final dataNested = literalMap({'data': result});

  return switch (type) {
    ClientType(isStringContent: true) => result,
    ClientType(isBytes: true) => result,
    _ => dataNested,
  };
}
