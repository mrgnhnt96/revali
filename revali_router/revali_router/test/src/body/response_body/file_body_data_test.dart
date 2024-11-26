import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:revali_router/revali_router.dart';
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

      final bodyData = FileBodyData(file);

      final result = await bodyData.read().toList();
      expect(result, [bytes]);
    });

    test('read can be called multiple types', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      final file = fs.file('test.txt')..writeAsBytesSync(bytes);

      final bodyData = FileBodyData(file);

      final result1 = await bodyData.read().toList();
      final result2 = await bodyData.read().toList();

      expect(result1, [bytes]);
      expect(result2, [bytes]);
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

    test('range should return length of data if end is null', () async {
      final file = fs.file('/path/to/file')..createSync(recursive: true);

      final bytes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
      file.writeAsBytesSync(bytes);

      final result = await FileBodyData(file).range(2, null).toList();
      expect(result, [
        [3, 4, 5, 6, 7, 8, 9, 10],
      ]);
    });

    test('cleanRange returns correct range values', () {
      final file = fs.file('/path/to/file')
        ..createSync(recursive: true)
        ..writeAsBytesSync(Uint8List(100));

      final result = FileBodyData(file).cleanRange(2, 5);
      expect(result, (2, 5, 100));
    });

    test('cleanRange returns all values if start is larger than length',
        () async {
      final file = fs.file('/path/to/file')
        ..createSync(recursive: true)
        ..writeAsBytesSync(Uint8List(100));

      final result = FileBodyData(file).cleanRange(101, 105);
      expect(result, (0, 99, 100));
    });

    test('headers returns correct headers', () {
      final file = fs.file('test.txt')..writeAsBytesSync(Uint8List(100));

      final headers = FileBodyData(file).headers(null);
      expect(headers.contentLength, 100);
      expect(headers.mimeType, 'text/plain');
    });

    test('headers returns correct headers with range', () {
      final file = fs.file('/path/to/file')
        ..createSync(recursive: true)
        ..writeAsBytesSync(Uint8List(100));

      final requestHeaders = MutableHeadersImpl({
        'range': ['bytes=2-5'],
      });

      final headers = FileBodyData(file).headers(requestHeaders);
      expect(headers.contentLength, 4);
      expect(headers.mimeType, 'application/octet-stream');
      expect(headers.range, isNull);
      expect(headers.contentRange, (2, 5, 100));
      expect(headers['Content-Range'], 'bytes 2-5/100');
    });
  });
}
