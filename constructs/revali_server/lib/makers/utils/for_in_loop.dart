import 'package:code_builder/code_builder.dart';

Expression forInLoop({
  required Expression declaration,
  required Expression iterable,
  Code? body,
  bool blockBody = true,
}) {
  if ((blockBody, body) case (false, null)) {
    throw ArgumentError('body is required when blockBody is false');
  }

  return CodeExpression(
    Block.of([
      const Code('for ('),
      declaration.code,
      const Code(' in '),
      iterable.code,
      const Code(') '),
      if (blockBody) const Code('{'),
      if (body case final body?) body,
      if (blockBody) const Code('}'),
    ]),
  );
}
