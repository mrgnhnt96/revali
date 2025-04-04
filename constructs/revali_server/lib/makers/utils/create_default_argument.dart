import 'package:code_builder/code_builder.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/makers/utils/create_switch_pattern.dart';

Expression createDefaultArgument(Expression variable, ServerParam param) {
  final defaultArgument = param.defaultValue;

  if (defaultArgument == null) {
    return variable;
  }

  return createSwitchPattern(variable, {
    declareFinal('value', type: refer(param.type.nonNullName)): refer('value'),
    const Code('_'): CodeExpression(Code(defaultArgument)),
  });
}
