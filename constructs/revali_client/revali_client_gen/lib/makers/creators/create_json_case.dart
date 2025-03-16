import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/models/client_type.dart';

Expression createJsonCase(ClientType type, {required bool isWebsocket}) {
  if (type.isFuture) {
    if (type.typeArguments.length != 1) {
      throw Exception('Future must have exactly one type argument');
    }

    final typeArgument = type.typeArguments.first;

    return createJsonCase(typeArgument, isWebsocket: isWebsocket);
  }

  if (type.isStream) {
    if (type.typeArguments.length != 1) {
      throw Exception('Stream must have exactly one type argument');
    }

    final typeArgument = type.typeArguments.first;

    return createJsonCase(typeArgument, isWebsocket: isWebsocket);
  }

  final data = declareFinal(
    'data',
    type: switch (type) {
      final e when e.isIterable => refer('List<dynamic>'),
      final e when e.isPrimitive => refer(e.name),
      _ => refer('Map<dynamic, dynamic>'),
    },
  );

  if (type.isStringContent) {
    return data;
  }

  return literalMap({'data': data});
}
