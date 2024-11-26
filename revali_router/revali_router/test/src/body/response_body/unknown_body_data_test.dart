import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:test/test.dart';

void main() {
  group(UnknownBodyData, () {
    test('should create an instance with given data and mimeType', () {
      final data = [
        [0x01, 0x02, 0x03],
      ];
      const mimeType = 'application/octet-stream';
      final unknownBodyData = UnknownBodyData(data, mimeType: mimeType);

      expect(unknownBodyData.data, data);
      expect(unknownBodyData.mimeType, mimeType);
    });

    test('should handle empty data', () {
      final data = <List<int>>[];
      const mimeType = 'application/octet-stream';
      final unknownBodyData = UnknownBodyData(data, mimeType: mimeType);

      expect(unknownBodyData.data, data);
      expect(unknownBodyData.mimeType, mimeType);
    });

    test('should handle null mimeType', () {
      final data = [
        [0x01, 0x02, 0x03],
      ];
      const mimeType = 'application/octet-stream';
      final unknownBodyData = UnknownBodyData(data, mimeType: mimeType);

      expect(unknownBodyData.data, data);
      expect(unknownBodyData.mimeType, mimeType);
    });
  });
}
