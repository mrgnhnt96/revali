import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/creators/create_future_call.dart';
import 'package:revali_client_gen/makers/creators/create_signature.dart';
import 'package:revali_client_gen/makers/creators/create_stream_call.dart';
import 'package:revali_client_gen/makers/creators/create_websocket_call.dart';
import 'package:revali_client_gen/models/client_method.dart';
import 'package:revali_client_gen/models/client_type.dart';

Method createImplMethod(ClientMethod method) {
  return createSignature(
    method,
    body: Block.of(
      switch (method) {
        ClientMethod(isSse: true, returnType: [ClientType(isVoid: false)]) =>
          createStreamCall(method),
        ClientMethod(isWebsocket: true) => createWebsocketCall(method),
        ClientMethod(
          returnType: ClientType(typeForClient: ClientType(isStream: true))
        ) =>
          createStreamCall(method),
        _ => createFutureCall(method),
      },
    ),
  );
}
