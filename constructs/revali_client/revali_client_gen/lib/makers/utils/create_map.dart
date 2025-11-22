import 'package:code_builder/code_builder.dart';

Expression createMap(
  Map<Object, dynamic> map, {
  Code Function(Reference)? ref,
}) {
  return CodeExpression(
    Block.of([
      const Code('{'),
      for (final MapEntry(:key, :value) in map.entries) ...[
        literal(key).code,
        const Code(':'),
        switch (value) {
          final Map<Object, dynamic> nestedMap => createMap(
            nestedMap,
            ref: ref,
          ).code,
          Code() => value,
          Reference() => value.code,
          CodeExpression() => value.code,
          _ => throw ArgumentError('Invalid value type: ${value.runtimeType}'),
        },
        const Code(','),
      ],
      if (ref case final ref?) ref(refer('}')) else const Code('}'),
    ]),
  );
}
