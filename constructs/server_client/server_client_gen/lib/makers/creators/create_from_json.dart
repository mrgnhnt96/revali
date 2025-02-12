import 'package:code_builder/code_builder.dart';
import 'package:server_client_gen/models/client_return_type.dart';

Expression createFromJson(
  ClientReturnType method,
  String variable, {
  bool forceMapType = false,
}) {
  Expression element = refer(variable);

  if (forceMapType) {
    element = element.asA(refer('Map'));
  }

  element = element.property('cast').call([]);

  return refer(method.resolvedName).newInstanceNamed(
    'fromJson',
    [element],
  );
}
