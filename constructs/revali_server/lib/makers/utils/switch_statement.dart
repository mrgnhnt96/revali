import 'package:code_builder/code_builder.dart';

Expression switchPatternStatement(
  Expression expression, {
  required Iterable<(Code, Code)> cases,
}) {
  return CodeExpression(
    Block.of([
      const Code('switch ('),
      expression.code,
      const Code(') {'),
      for (final (c, result) in cases)
        Block.of([
          c,
          refer('=>').code,
          result,
          const Code(','),
        ]),
      const Code('}'),
    ]),
  );
}
