import 'package:code_builder/code_builder.dart';

Expression ifStatement(
  Expression expression, {
  ({Expression cse, Expression? when})? pattern,
  Code? body,
}) {
  return CodeExpression(
    Block.of([
      const Code('if ('),
      expression.code,
      if (pattern != null)
        Block.of([
          const Code(' case '),
          pattern.cse.code,
          if (pattern.when case final whn?) ...[const Code(' when '), whn.code],
        ]),
      const Code(') {'),
      if (body case final body?) body,
      const Code('}'),
    ]),
  );
}
