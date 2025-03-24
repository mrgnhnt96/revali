import 'dart:async';
import 'dart:convert';

import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:test/test.dart';

void main() {
  group('StreamBodyData', () {
    test('should return correct mimeType', () {
      final data = StreamBodyData(const Stream<void>.empty());
      expect(data.mimeType, 'application/octet-stream');
    });

    test('should return correct filename', () {
      final data =
          StreamBodyData(const Stream<void>.empty(), filename: 'test.txt');
      expect(data.filename, 'test.txt');
    });

    test('should return correct contentLength', () {
      final data =
          StreamBodyData(const Stream<void>.empty(), contentLength: 100);
      expect(data.contentLength, 100);
    });

    test('should transform Stream of String to Stream of List of int',
        () async {
      final data = StreamBodyData(Stream.fromIterable(['test']));
      final result = await data.read().toList();
      expect(result, [utf8.encode('test')]);
    });

    test('should transform Stream<Map> to Stream<List<int>>', () async {
      final data = StreamBodyData(
        Stream.value({'key': 'value'}),
      );
      final result = await data.read().toList();
      expect(result, [
        utf8.encode(jsonEncode({'key': 'value'})),
      ]);
    });

    test('should convert value to string when encode fails', () async {
      final data = StreamBodyData(
        Stream.value({'key', 'value'}),
      );
      final result = await data.read().toList();
      expect(result, [
        utf8.encode('{key, value}'),
      ]);
    });

    test('should convert null to empty list', () async {
      final data = StreamBodyData(Stream.value(null));
      final result = await data.read().toList();
      // ignore: inference_failure_on_collection_literal
      expect(result, [[]]);
    });

    test('should handle strings', () async {
      final data = StreamBodyData(Stream.value('test'));
      final result = await data.read().toList();
      expect(result, [utf8.encode('test')]);
    });

    test('should handle unknown stream types', () async {
      final data = StreamBodyData(Stream.fromIterable([123]));
      final result = await data.read().toList();
      expect(result, [utf8.encode('123')]);
    });

    test('should return correct headers', () {
      final data = StreamBodyData(
        const Stream<void>.empty(),
        contentLength: 100,
        filename: 'test.txt',
      );
      final headers = data.headers(null);
      expect(headers.mimeType, 'application/octet-stream');
      expect(headers.filename, 'test.txt');
      expect(headers.contentLength, 100);
    });
  });
}
