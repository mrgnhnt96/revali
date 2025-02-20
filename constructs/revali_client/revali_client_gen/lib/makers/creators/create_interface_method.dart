import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/creators/get_parameters.dart';
import 'package:revali_client_gen/makers/creators/get_path_params.dart';
import 'package:revali_client_gen/models/client_method.dart';

Method createInterfaceMethod(ClientMethod method) {
  return Method(
    (b) => b
      ..name = method.name
      ..returns = switch (method.returnType) {
        final e when e.isStringContent => refer('Future<String>'),
        final e when e.isStream => refer(e.fullName),
        final e when e.isFuture => refer(e.fullName),
        final e => refer('Future<${e.fullName}>')
      }
      ..optionalParameters.addAll(getPathParams(method))
      ..optionalParameters.addAll(getParameters(method.allParams, method)),
  );
}
