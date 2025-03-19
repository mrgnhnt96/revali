import 'package:code_builder/code_builder.dart';

Expression forInLoop({
  required Expression declaration,
  required Expression iterable,
  Code? body,
}) {
  return CodeExpression(
    Block.of([
      const Code('for ('),
      declaration.code,
      const Code(' in '),
      iterable.code,
      const Code(') {'),
      if (body case final body?) body,
      const Code('}'),
    ]),
  );
}
