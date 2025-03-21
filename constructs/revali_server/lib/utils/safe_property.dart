import 'package:code_builder/code_builder.dart';
import 'package:revali_server/converters/server_type.dart';

extension SafeProperty on Expression {
  Expression safeProperty(ServerType type, String name) {
    if (type.isNullable) {
      return nullSafeProperty(name);
    }

    return property(name);
  }
}
