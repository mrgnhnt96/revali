import 'package:code_builder/code_builder.dart';
import 'package:server_client_gen/makers/creators/create_future_call.dart';
import 'package:server_client_gen/makers/creators/create_stream_call.dart';
import 'package:server_client_gen/makers/creators/create_websocket_call.dart';
import 'package:server_client_gen/makers/utils/get_parameters.dart';
import 'package:server_client_gen/makers/utils/get_path_params.dart';
import 'package:server_client_gen/models/client_method.dart';

Method createImplMethod(ClientMethod method) {
  return Method(
    (b) => b
      ..name = method.name
      ..returns = switch (method.returnType) {
        final e when e.isStream => refer(e.fullName),
        final e when e.isStringContent => refer('Future<String>'),
        final e => refer('Future<${e.fullName}>')
      }
      ..optionalParameters.addAll(getPathParams(method))
      ..optionalParameters.addAll(getParameters(method.allParams))
      ..annotations.add(refer('override'))
      ..modifier = switch (method.returnType) {
        final e when e.isStream => MethodModifier.asyncStar,
        _ => MethodModifier.async
      }
      ..body = Block.of(
        switch (method) {
          final m when m.isSse => createStreamCall(m),
          final m when m.isWebsocket => createWebsocketCall(m),
          final m when m.returnType.isStream => createStreamCall(m),
          final m => createFutureCall(m),
        },
      ),
  );
}
