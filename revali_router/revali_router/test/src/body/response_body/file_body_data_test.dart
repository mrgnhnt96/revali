import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:test/test.dart';

void main() {
  group(FileBodyData, () {
    late FileSystem fs;

    setUp(() {
      fs = MemoryFileSystem.test();
      FileBodyData.fs = fs;
    });

    test('mimeType returns correct mime type', () {
      final file = fs.file('test.txt')..writeAsStringSync('test');

      expect(FileBodyData(file).mimeType, 'text/plain');
    });

    test('contentLength returns correct length', () {
      final file = fs.file('test.txt')..writeAsBytesSync(Uint8List(100));

      expect(FileBodyData(file).contentLength, 100);
    });

    test('read returns correct stream of bytes', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      final file = fs.file('test.txt')..writeAsBytesSync(bytes);

      final result = await FileBodyData(file).read().toList();
      expect(result, [bytes]);
    });

    test('file returns resolved sym link path', () {
      fs.file('/resolved/path/to/file').createSync(recursive: true);
      fs
          .link('path/to/file')
          .createSync('/resolved/path/to/file', recursive: true);

      final file = fs.file('/path/to/file');

      expect(FileBodyData(file).file.path, '/resolved/path/to/file');
    });

    test('range returns correct byte range', () async {
      final file = fs.file('/path/to/file')..createSync(recursive: true);

      final bytes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
      file.writeAsBytesSync(bytes);

      final result = await FileBodyData(file).range(2, 5).toList();
      expect(result, [
        [3, 4, 5, 6],
      ]);
    });

    test('cleanRange returns correct range values', () {
      final file = fs.file('/path/to/file')
        ..createSync(recursive: true)
        ..writeAsBytesSync(Uint8List(100));

      final result = FileBodyData(file).cleanRange(2, 5);
      expect(result, (2, 5, 4));
    });

    test('headers returns correct headers', () {
      final file = fs.file('test.txt')..writeAsBytesSync(Uint8List(100));

      final headers = FileBodyData(file).headers(null);
      expect(headers.contentLength, 100);
      expect(headers.mimeType, 'text/plain');
    });
  });
}
