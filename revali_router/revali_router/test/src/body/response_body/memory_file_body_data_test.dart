import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:revali_router_core/revali_router_core.dart';
import 'package:test/test.dart';

void main() {
  group(MemoryFileBodyData, () {
    late MemoryFile memoryFile;
    late MemoryFileBodyData memoryFileBodyData;

    setUp(() {
      memoryFile = const MemoryFile(
        [1, 2, 3, 4, 5],
        mimeType: 'application/octet-stream',
        basename: 'testfile',
        extension: 'bin',
      );
      memoryFileBodyData = MemoryFileBodyData(memoryFile);
    });

    test('mimeType returns correct MIME type', () {
      expect(memoryFileBodyData.mimeType, 'application/octet-stream');
    });

    test('contentLength returns correct length', () {
      expect(memoryFileBodyData.contentLength, 5);
    });

    test('read returns correct stream of bytes', () async {
      final bytes = await memoryFileBodyData.read().toList();
      expect(bytes, [
        [1, 2, 3, 4, 5],
      ]);
    });

    test('headers returns correct headers', () {
      final headers = memoryFileBodyData.headers(null);
      expect(headers.mimeType, 'application/octet-stream');
      expect(headers.contentLength, 5);
      expect(headers.filename, 'testfile.bin');
    });
  });
}
