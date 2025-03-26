// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_server/converters/server_type.dart';
import 'package:revali_server/makers/utils/switch_statement.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';

Expression createFromJsonArg(ServerType type, {required Expression access}) {
  if (!type.isNullable) {
    return refer(type.nonNullName).property('fromJson').call([access]);
  }

  return switchPatternStatement(
    access,
    cases: [
      (
        declareFinal('data', type: refer((Map).name)).code,
        refer(type.nonNullName).property('fromJson').call([
          refer((Map).name).newInstanceNamed('from', [
            refer('data').asA(refer((Map).name)),
          ]),
        ]).code,
      ),
      (
        const Code('_'),
        switch (type.isNullable) {
          true => literalNull.code,
          false => refer('ArgumentError').newInstance([
              literalString('Cannot convert non-Map value to ${type.name}'),
            ]).code,
        }
      ),
    ],
  );
}
