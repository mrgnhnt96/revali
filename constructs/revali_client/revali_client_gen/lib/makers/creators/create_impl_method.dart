import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/creators/create_future_call.dart';
import 'package:revali_client_gen/makers/creators/create_signature.dart';
import 'package:revali_client_gen/makers/creators/create_stream_call.dart';
import 'package:revali_client_gen/makers/creators/create_websocket_call.dart';
import 'package:revali_client_gen/models/client_method.dart';

Method createImplMethod(ClientMethod method) {
  return createSignature(
    method,
    body: Block.of(
      switch (method) {
        final m when m.isSse => createStreamCall(m),
        final m when m.isWebsocket => createWebsocketCall(m),
        final m when m.returnType.isStream => createStreamCall(m),
        final m => createFutureCall(m),
      },
    ),
  );
}
