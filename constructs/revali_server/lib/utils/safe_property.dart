import 'package:code_builder/code_builder.dart';
import 'package:revali_server/converters/server_type.dart';
import 'package:revali_server/makers/utils/binary_expression_extensions.dart';

extension SafeProperty on Expression {
  Expression safeProperty(ServerType type, String name) {
    if (type.isNullable) {
      return nullSafeProperty(name);
    }

    return property(name);
  }

  Expression safeIndex(ServerType type, Expression variable) {
    if (type.isNullable) {
      return nullSafeIndex(variable);
    }

    return index(variable);
  }
}
