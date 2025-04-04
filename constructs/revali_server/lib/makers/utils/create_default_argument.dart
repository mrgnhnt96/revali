import 'package:code_builder/code_builder.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/makers/creators/create_from_json.dart';
import 'package:revali_server/makers/creators/get_raw_type.dart';
import 'package:revali_server/makers/utils/create_switch_pattern.dart';

Expression? createDefaultArgument(Expression variable, ServerParam param) {
  final defaultArgument = param.defaultValue;

  if (defaultArgument == null) {
    return null;
  }

  final serialized =
      createFromJson(param.type, refer('value')) ?? refer('value');

  return createSwitchPattern(variable, {
    if (param.type.hasFromJson)
      Block.of([
        if (getRawType(param.type) case final type) ...[
          declareFinal('value', type: type).code,
          if (type.symbol case final String symbol
              when symbol.startsWith('Map')) ...[
            const Code('when'),
            refer('value').property('isNotEmpty').code,
          ],
        ],
      ]): serialized
    else
      declareFinal('value', type: refer(param.type.nonNullName)): serialized,
    const Code('_'): CodeExpression(Code(defaultArgument)),
  });
}
