import 'package:code_builder/code_builder.dart';
import 'package:revali_server/utils/annotation_arguments.dart';

List<Parameter> createConstructorParameters(
  AnnotationArguments arguments,
) {
  Iterable<Parameter> iterate() sync* {
    for (final arg in arguments.positional) {
      yield Parameter(
        (p) => p
          ..name = arg.parameterName
          ..toThis = true
          ..named = true
          ..required = true,
      );
    }

    for (final MapEntry(:key, :value) in arguments.named.entries) {
      yield Parameter(
        (p) => p
          ..name = key
          ..toThis = true
          ..named = true
          ..required = value.isRequired,
      );
    }
  }

  return iterate().toList();
}
