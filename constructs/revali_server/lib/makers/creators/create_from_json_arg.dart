// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_server/converters/server_type.dart';
import 'package:revali_server/makers/utils/switch_statement.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';

Expression createFromJsonArg(ServerType type, {required Expression access}) {
  Expression mappedAccess(Expression variable) {
    return refer((Map).name).newInstanceNamed('from', [
      variable.asA(refer((Map).name)),
    ]);
  }

  if (!type.isNullable) {
    return refer(type.nonNullName)
        .property('fromJson')
        .call([mappedAccess(access)]);
  }

  return switchPatternStatement(
    access,
    cases: [
      (
        declareFinal('data', type: refer((Map).name)).code,
        refer(type.nonNullName)
            .property('fromJson')
            .call([mappedAccess(refer('data'))]).code,
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
