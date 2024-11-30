import 'package:code_builder/code_builder.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/makers/creators/create_param_arg.dart';

({Iterable<Expression> positioned, Map<String, Expression> named}) getParams(
  Iterable<ServerParam> params, {
  Expression? defaultExpression,
  Map<String, Expression> inferredParams = const {},
}) {
  final positioned = <Expression>[];
  final named = <String, Expression>{};

  for (final param in params) {
    final arg = createParamArg(
      param,
      defaultExpression: defaultExpression,
      customParams: inferredParams,
    );

    if (param.isNamed) {
      named[param.name] = arg;
    } else {
      positioned.add(arg);
    }
  }
  return (positioned: positioned, named: named);
}
