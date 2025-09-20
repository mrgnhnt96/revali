import 'package:code_builder/code_builder.dart';
import 'package:revali_server/converters/server_param.dart';

List<Parameter> createConstructorParameters(List<ServerParam> params) {
  Iterable<Parameter> iterate() sync* {
    for (final arg in params) {
      yield Parameter(
        (p) => p
          ..name = arg.name
          ..toThis = true
          ..named = true
          ..required = arg.isRequired
          ..defaultTo = switch (arg.defaultValue) {
            final String value => Code(value),
            _ => null,
          },
      );
    }
  }

  return iterate().toList();
}
