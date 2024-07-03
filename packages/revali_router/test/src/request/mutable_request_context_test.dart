import 'package:mockito/mockito.dart';
import 'package:revali_router/src/request/mutable_request_context.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  group('$MutableRequestContext', () {
    group('#merge', () {
      test('merges header gracefully', () {
        final firstRequest = _FakeRequest();
        final secondRequest = _FakeRequest(headers: {'key': 'value'});

        final context = MutableRequestContext(firstRequest);
        final other = MutableRequestContext(secondRequest);

        final merged = context.merge(other);

        expect(merged.headers, containsPair('key', 'value'));
      });
    });
  });
}

class _FakeRequest extends Fake implements Request {
  _FakeRequest({this.headers = const {}});

  @override
  final Map<String, String> headers;
}
