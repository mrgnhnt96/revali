import 'package:code_builder/code_builder.dart';

import '../../models/client_method.dart';
import '../utils/get_params.dart';

Method createImplMethod(ClientMethod method) {
  return Method(
    (b) => b
      ..name = method.name
      ..returns = switch (method.returnType) {
        final e when e.isStream => refer(e.name),
        final e => refer('Future<${e.name}>')
      }
      ..optionalParameters.addAll(getParams(method.parameters)),
  );
}
