import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/creators/create_stream_call.dart';
import 'package:revali_client_gen/models/client_method.dart';
import 'package:revali_client_gen/models/client_type.dart';
import 'package:revali_client_gen/models/websocket_type.dart';
import 'package:test/test.dart';

void main() {
  group('createStreamCall', () {
    ClientMethod method(ClientType returnType) => ClientMethod(
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

    ClientType stream(String arg) =>
        ClientType(name: 'Stream', isStream: true, typeArguments: [ClientType(name: arg)]);

    String emit(ClientType returnType) {
      final emitter = DartEmitter.scoped(useNullSafetySyntax: true);
      return createStreamCall(method(returnType))
          .map((c) => c.accept(emitter).toString())
          .join('\n');
    }

    // Both call sites must narrow. The bytes branch (fromJson == null) and the
    // mapOver branch are separate codepaths through this file, and a fixture
    // for only one of them lets the bug be reintroduced on the other.
    for (final (name, arg) in [('mapOver', 'String'), ('bytes', 'List<int>')]) {
      test('narrows the swallow on the $name branch', () {
        final result = emit(stream(arg));

        expect(result, contains('handleError'), reason: 'suppression is kept');
        expect(
          result,
          contains('test: isTransportError'),
          reason: 'an unconditional handleError also eats decode and app errors',
        );
      });

      test('refers to the predicate by BARE name on the $name branch', () {
        // This generator writes its imports by hand and unprefixed, and the
        // emitted class lands in a `part` file which cannot carry imports. A
        // prefixed reference (_i1.isTransportError) therefore emits code whose
        // import is never written: "Undefined name '_i1'".
        final result = emit(stream(arg));

        expect(result, isNot(contains('_i')), reason: 'a prefix here does not compile');
      });
    }
  });
}
