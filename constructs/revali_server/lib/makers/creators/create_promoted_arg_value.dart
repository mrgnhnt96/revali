import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/models/iterable_type.dart';
import 'package:revali_server/converters/server_type.dart';

/// The runtime shape exposed by headers, query, path, or resolved body.
ServerType bindingSourceType(ServerType type) {
  if (type.isStream && type.typeArguments.length == 1) {
    return type.typeArguments.first;
  }

  if (type.isFuture && type.typeArguments.length == 1) {
    return type.typeArguments.first;
  }

  return type;
}

Expression createPromotedArgValue({
  required ServerType paramType,
  required Expression? fromJson,
}) {
  final sourceType = bindingSourceType(paramType);

  return fromJson ??
      switch (sourceType) {
        ServerType(:final iterableType?) => switch (iterableType) {
          IterableType.list => _typedCast(
            refer('data'),
            sourceType.typeArguments.firstOrNull,
          ),
          IterableType.set => _typedCast(
            refer('data').property('toSet').call([]),
            sourceType.typeArguments.firstOrNull,
          ),
          IterableType.iterable => refer('data'),
        },
        _ => refer('data'),
      };
}

Expression _typedCast(Expression data, ServerType? elementType) {
  if (elementType == null || elementType.isDynamic) {
    return data.property('cast').call([]);
  }

  return CodeExpression(
    Block.of([
      data.code,
      Code('.cast<${elementType.nonNullName}>()'),
    ]),
  );
}
