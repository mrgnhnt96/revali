// ignore_for_file: inference_failure_on_instance_creation

import 'dart:io';
import 'dart:typed_data';

import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:revali_router_core/revali_router_core.dart';
import 'package:test/test.dart';

void main() {
  group(BaseBodyData, () {
    test('should create StringBodyData from String', () {
      final data = BaseBodyData.from('test');
      expect(data, isA<StringBodyData>());
      expect(data.data, 'test');
    });

    test('should create JsonBodyData from Map<String, dynamic>', () {
      final data = BaseBodyData.from({'key': 'value'});
      expect(data, isA<JsonBodyData>());
      expect(data.data, {'key': 'value'});
    });

    test('should create JsonBodyData from Map', () {
      final data = BaseBodyData.from({'key': 'value'});
      expect(data, isA<JsonBodyData>());
      expect(data.data, {'key': 'value'});
    });

    test('should create NullBodyData from null', () {
      final data = BaseBodyData.from(null);
      expect(data, isA<NullBodyData>());
    });

    test('should create FileBodyData from File', () {
      final file = File('test.txt');
      final data = BaseBodyData.from(file);
      expect(data, isA<FileBodyData>());
      expect(data.data, file);
    });

    test('should create MemoryFileBodyData from MemoryFile', () {
      final memoryFile = MemoryFile.from('test.txt', mimeType: 'text/plain');
      final data = BaseBodyData.from(memoryFile);
      expect(data, isA<MemoryFileBodyData>());
      expect(data.data, memoryFile);
    });

    test('should create BinaryBodyData from Binary', () {
      final binary = [
        Uint8List.fromList([1, 2, 3]),
      ];
      final data = BaseBodyData.from(binary);
      expect(data, isA<BinaryBodyData>());
      expect(data.data, binary);
    });

    test('should create ListBodyData from List', () {
      final data = BaseBodyData.from([1, 2, 3]);
      expect(data, isA<ListBodyData>());
      expect(data.data, [1, 2, 3]);
    });

    test('should create ByteStreamBodyData from Stream<List<int>>', () {
      const stream = Stream<List<int>>.empty();
      final data = BaseBodyData.from(stream);
      expect(data, isA<ByteStreamBodyData>());
      expect(data.data, stream);
    });

    test('should create StreamBodyData from Stream<dynamic>', () {
      const stream = Stream<dynamic>.empty();
      final data = BaseBodyData.from(stream);
      expect(data, isA<StreamBodyData>());
      expect(data.data, stream);
    });

    test('should throw UnsupportedError for unsupported type', () {
      expect(() => BaseBodyData.from(123), throwsUnsupportedError);
    });
  });
}
