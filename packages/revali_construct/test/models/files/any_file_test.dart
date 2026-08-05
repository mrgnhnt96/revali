import 'package:revali_construct/models/files/any_file.dart';
import 'package:test/test.dart';

void main() {
  group(AnyFile, () {
    test('defaults to empty text content and no bytes', () {
      const file = AnyFile(basename: 'Dockerfile');

      expect(file.content, '');
      expect(file.bytes, isNull);
    });

    test('carries text content when bytes are not provided', () {
      const file = AnyFile(basename: 'Dockerfile', content: 'FROM alpine');

      expect(file.content, 'FROM alpine');
      expect(file.bytes, isNull);
    });

    test('carries binary content independently of content', () {
      final bytes = [0x7f, 0x45, 0x4c, 0x46];
      final file = AnyFile(basename: 'server', bytes: bytes);

      expect(file.bytes, bytes);
      expect(file.content, '');
    });
  });
}
