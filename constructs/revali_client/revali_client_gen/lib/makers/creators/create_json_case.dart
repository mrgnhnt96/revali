import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/utils/get_raw_type.dart';
import 'package:revali_client_gen/models/client_type.dart';

Expression createJsonCase(ClientType type) {
  final rawType = switch (getRawType(type)) {
    final t when t.endsWith('?') => t,
    final t when type.isNullable => '$t?',
    final t => t,
  };

  final result = declareFinal('data', type: refer(rawType));
  final dataNested = literalMap({'data': result});

  return switch (type) {
    ClientType(isStringContent: true) => result,
    ClientType(isBytes: true) => result,
    _ => dataNested,
  };
}
