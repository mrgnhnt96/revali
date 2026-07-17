import 'package:http/http.dart' show ClientException;
import 'package:revali_client/revali_client.dart';
import 'package:test/test.dart';

void main() {
  group('isTransportError', () {
    test('matches transport errors', () {
      expect(isTransportError(ClientException('Connection closed')), isTrue);
    });

    test('does NOT match a decode error — this is the whole point', () {
      // parseJson raises exactly this when a payload does not match the shape.
      // If this ever returns true, the generated client silently swallows a
      // decode failure and completes the stream normally.
      expect(isTransportError(Exception('Invalid response')), isFalse);
    });

    test('does NOT match an arbitrary application error', () {
      expect(isTransportError(StateError('boom')), isFalse);
      expect(isTransportError(FormatException('bad json')), isFalse);
    });

    test('binds to Stream.handleError test:', () {
      // Regression: `bool Function(Object)` does NOT bind here. handleError's
      // test: is declared `bool test(error)` -- i.e. bool Function(dynamic) --
      // and function parameters are contravariant. The parameter must be
      // nullable or this does not compile.
      expect(
        () => Stream<String>.empty().handleError((_) {}, test: isTransportError),
        returnsNormally,
      );
    });

    test('a decode error survives the generated handleError shape', () {
      // End to end on the emitted shape: the error must reach the consumer.
      final s = Stream<String>.error(Exception('Invalid response'))
          .handleError((_) {}, test: isTransportError);
      expect(s.toList(), throwsA(isA<Exception>()));
    });

    test('a transport error is swallowed by the generated shape', () {
      final s = Stream<String>.error(ClientException('gone'))
          .handleError((_) {}, test: isTransportError);
      expect(s.toList(), completion(isEmpty));
    });
  });
}
