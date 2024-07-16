import 'package:code_builder/code_builder.dart';
import 'package:revali_server/revali_server.dart';

({Iterable<Expression> positioned, Map<String, Expression> named}) getParams(
  Iterable<ServerParam> params,
) {
  final positioned = <Expression>[];
  final named = <String, Expression>{};

  for (final param in params) {
    final arg = createParamArg(param);

    if (param.isNamed) {
      named[param.name] = arg;
    } else {
      positioned.add(arg);
    }
  }
  return (positioned: positioned, named: named);
}
