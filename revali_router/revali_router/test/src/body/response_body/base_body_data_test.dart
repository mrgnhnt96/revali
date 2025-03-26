// ignore_for_file: inference_failure_on_instance_creation, strict_raw_type

import 'dart:io';
import 'dart:typed_data';

import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:revali_router_core/revali_router_core.dart';
import 'package:test/test.dart';

void main() {
  group('BaseBodyData', () {
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

    test('should create JsonBodyData from Map<String, dynamic>', () {
      final data = BaseBodyData.from({'key': 'value'});
      expect(data, isA<JsonBodyData>());
      expect(data.data, {'key': 'value'});
    });

    test('should create JsonBodyData from Map<dynamic, dynamic', () {
      final data = BaseBodyData.from({1: 'value'});
      expect(data, isA<JsonBodyData>());
      expect(data.data, {'1': 'value'});
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

    test('should create PrimitiveNonStringBodyData from int', () {
      final data = BaseBodyData.from(123);
      expect(data, isA<PrimitiveNonStringBodyData>());
      expect(data.data, 123);
    });

    test('should create PrimitiveNonStringBodyData from double', () {
      final data = BaseBodyData.from(123.456);
      expect(data, isA<PrimitiveNonStringBodyData>());
      expect(data.data, 123.456);
    });

    test('should create PrimitiveNonStringBodyData from bool', () {
      final data = BaseBodyData.from(true);
      expect(data, isA<PrimitiveNonStringBodyData>());
      expect(data.data, true);
    });

    test('should throw UnsupportedError for unsupported type', () {
      expect(() => BaseBodyData.from(('123', 'two')), throwsUnsupportedError);
    });

    group('bool checks', () {
      test('isNull should be true for NullBodyData', () {
        final data = BaseBodyData.from(null);
        expect(data.isNull, isTrue);
      });

      test('isBinary should be true for BinaryBodyData', () {
        final binary = [
          Uint8List.fromList([1, 2, 3]),
        ];
        final data = BaseBodyData.from(binary);
        expect(data.isBinary, isTrue);
      });

      test('isString should be true for StringBodyData', () {
        final data = BaseBodyData.from('test');
        expect(data.isString, isTrue);
      });

      test('isJson should be true for JsonBodyData', () {
        final data = BaseBodyData.from({'key': 'value'});
        expect(data.isJson, isTrue);
      });

      test('isList should be true for ListBodyData', () {
        final data = BaseBodyData.from([1, 2, 3]);
        expect(data.isList, isTrue);
      });

      test('isFormData should be true for FormDataBodyData', () {
        final formData = FormDataBodyData({});
        final data = BaseBodyData.from(formData);
        expect(data.isFormData, isTrue);
      });

      test('isStream should be true for StreamBodyData', () {
        const stream = Stream<dynamic>.empty();
        final data = BaseBodyData.from(stream);
        expect(data.isStream, isTrue);
      });

      test('isFile should be true for FileBodyData', () {
        final file = File('test.txt');
        final data = BaseBodyData.from(file);
        expect(data.isFile, isTrue);
      });

      test('isMemoryFile should be true for MemoryFileBodyData', () {
        final memoryFile = MemoryFile.from('test.txt', mimeType: 'text/plain');
        final data = BaseBodyData.from(memoryFile);
        expect(data.isMemoryFile, isTrue);
      });

      test('isByteStream should be true for ByteStreamBodyData', () {
        const stream = Stream<List<int>>.empty();
        final data = BaseBodyData.from(stream);
        expect(data.isByteStream, isTrue);
      });
    });

    group('type casting', () {
      test('asNull should cast to NullBodyData', () {
        final data = BaseBodyData.from(null);
        expect(data.asNull, isA<NullBodyData>());
      });

      test('asBinary should cast to BinaryBodyData', () {
        final binary = [
          Uint8List.fromList([1, 2, 3]),
        ];
        final data = BaseBodyData.from(binary);
        expect(data.asBinary, isA<BinaryBodyData>());
      });

      test('asString should cast to StringBodyData', () {
        final data = BaseBodyData.from('test');
        expect(data.asString, isA<StringBodyData>());
      });

      test('asJson should cast to JsonBodyData', () {
        final data = BaseBodyData.from({'key': 'value'});
        expect(data.asJson, isA<JsonBodyData>());
      });

      test('asList should cast to ListBodyData', () {
        final data = BaseBodyData.from([1, 2, 3]);
        expect(data.asList, isA<ListBodyData>());
      });

      test('asFormData should cast to FormDataBodyData', () {
        final formData = FormDataBodyData({});
        final data = BaseBodyData.from(formData);
        expect(data.asFormData, isA<FormDataBodyData>());
      });

      test('asStream should cast to StreamBodyData', () {
        const stream = Stream<dynamic>.empty();
        final data = BaseBodyData.from(stream);
        expect(data.asStream, isA<StreamBodyData>());
      });

      test('asFile should cast to FileBodyData', () {
        final file = File('test.txt');
        final data = BaseBodyData.from(file);
        expect(data.asFile, isA<FileBodyData>());
      });

      test('asMemoryFile should cast to MemoryFileBodyData', () {
        final memoryFile = MemoryFile.from('test.txt', mimeType: 'text/plain');
        final data = BaseBodyData.from(memoryFile);
        expect(data.asMemoryFile, isA<MemoryFileBodyData>());
      });

      test('asByteStream should cast to ByteStreamBodyData', () {
        const stream = Stream<List<int>>.empty();
        final data = BaseBodyData.from(stream);
        expect(data.asByteStream, isA<ByteStreamBodyData>());
      });
    });
  });
}
