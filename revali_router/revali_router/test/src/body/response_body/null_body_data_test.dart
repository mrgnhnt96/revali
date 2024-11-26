import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:revali_router/src/headers/mutable_headers_impl.dart';
import 'package:test/test.dart';

void main() {
  group(NullBodyData, () {
    late NullBodyData nullBodyData;

    setUp(() {
      nullBodyData = NullBodyData();
    });

    test('isNull should return true', () {
      expect(nullBodyData.isNull, isTrue);
    });

    test('mimeType should return null', () {
      expect(nullBodyData.mimeType, isNull);
    });

    test('contentLength should be 0', () {
      expect(nullBodyData.contentLength, 0);
    });

    test('read should return an empty stream', () async {
      final stream = nullBodyData.read();
      expect(await stream.isEmpty, isTrue);
    });

    test('headers should return an instance of $MutableHeadersImpl', () {
      final headers = nullBodyData.headers(null);
      expect(headers, isA<MutableHeadersImpl>());
    });
  });
}
