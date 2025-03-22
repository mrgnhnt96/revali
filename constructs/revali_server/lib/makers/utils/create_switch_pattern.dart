import 'package:code_builder/code_builder.dart';

Expression createSwitchPattern(
  Expression variable,
  Map<Spec, Expression> cases,
) {
  return CodeExpression(
    Block.of([
      const Code('switch ('),
      variable.code,
      const Code(') {'),
      ...cases.entries.expand(
        (e) => [
          switch (e.key) {
            final Code code => code,
            final Expression exp => exp.code,
            final key => throw ArgumentError.value(key),
          },
          const Code(' => '),
          e.value.code,
          const Code(','),
        ],
      ),
      const Code('}'),
    ]),
  );
}
