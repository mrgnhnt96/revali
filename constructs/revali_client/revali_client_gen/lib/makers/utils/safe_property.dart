import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/utils/binary_expression_extensions.dart';
import 'package:revali_client_gen/models/client_type.dart';

extension SafeProperty on Expression {
  Expression safeProperty(ClientType type, String name) {
    if (type.isNullable) {
      return nullSafeProperty(name);
    }

    return property(name);
  }

  Expression safeIndex(ClientType type, Expression variable) {
    if (type.isNullable) {
      return nullSafeIndex(variable);
    }

    return index(variable);
  }
}
