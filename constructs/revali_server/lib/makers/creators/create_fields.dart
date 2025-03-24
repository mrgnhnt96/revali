import 'package:code_builder/code_builder.dart';
import 'package:revali_server/converters/server_param.dart';

List<Field> createFields(List<ServerParam> params) {
  Iterable<Field> iterate() sync* {
    for (final ServerParam(:name, :type) in params) {
      yield Field(
        (p) => p
          ..type = refer(type.name)
          ..name = name
          ..modifier = FieldModifier.final$,
      );
    }
  }

  return iterate().toList();
}
