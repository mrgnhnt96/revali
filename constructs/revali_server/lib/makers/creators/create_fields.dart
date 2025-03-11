import 'package:code_builder/code_builder.dart';
import 'package:revali_server/utils/annotation_arguments.dart';

List<Field> createFields(AnnotationArguments arguments) {
  Iterable<Field> iterate() sync* {
    for (final arg in arguments.positional) {
      yield Field(
        (p) => p
          ..type = refer(arg.type.name)
          ..name = arg.parameterName
          ..modifier = FieldModifier.final$,
      );
    }
  }

  return iterate().toList();
}
