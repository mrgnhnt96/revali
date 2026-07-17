import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/creators/create_stream_call.dart';
import 'package:revali_client_gen/models/client_method.dart';
import 'package:revali_client_gen/models/client_type.dart';
import 'package:revali_client_gen/models/websocket_type.dart';
import 'package:test/test.dart';

void main() {
  group('createStreamCall', () {
    ClientMethod method({required ClientType returnType}) {
      return ClientMethod(
        name: 'name',
        parameters: [],
        lifecycleComponents: [],
        returnType: returnType,
        isSse: true,
        websocketType: WebsocketType.none,
        path: 'path',
        parentPath: '',
        method: 'GET',
        isExcluded: false,
      );
    }

    ClientType stringStream() => ClientType(
          name: 'Stream',
          typeArguments: [ClientType(name: 'String')],
        );

    String emit(List<Code> code) {
      final emitter = DartEmitter.scoped(useNullSafetySyntax: true);
      return code.map((c) => c.accept(emitter).toString()).join('\n');
    }

    test('swallows disconnects', () {
      // The suppression from 3687886c is preserved: a peer going away must not
      // throw into user code.
      final result = emit(createStreamCall(method(returnType: stringStream())));

      expect(result, contains('handleError'));
    });

    test('does NOT swallow every error — the swallow is narrowed by test:', () {
      // The regression this guards. handleError WITHOUT a test: swallows
      // everything and completes the stream normally, so a decode failure
      // (parseJson raises Exception('Invalid response')) arrived as an
      // empty-but-successful stream, and a crashed stream was
      // indistinguishable from a finished one.
      final result = emit(createStreamCall(method(returnType: stringStream())));

      expect(
        result,
        contains('test:'),
        reason: 'an unconditional handleError also eats decode and app errors',
      );
      expect(result, contains('isDisconnectError'));
    });
  });
}
