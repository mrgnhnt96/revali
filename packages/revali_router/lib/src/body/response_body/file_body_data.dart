part of 'base_body_data.dart';

final class FileBodyData extends BaseBodyData<File> {
  FileBodyData(super.data);

  @override
  String? get mimeType {
    return lookupMimeType(file.path);
  }

  @override
  int get contentLength {
    return data.lengthSync();
  }

  List<int>? _bytes;
  @override
  Stream<List<int>> read() async* {
    if (_bytes case final bytes?) {
      yield* Stream.fromIterable([bytes]);
    }
    final bytes = _bytes = data.readAsBytesSync();

    yield* Stream.value(bytes);
  }

  File? _file;
  File get file {
    if (_file case final file?) {
      return file;
    }

    final path = File(data.path).resolveSymbolicLinksSync();

    return _file = File(path);
  }

  Stream<List<int>> range(int start, int end) async* {
    final (start0, _, length) = cleanRange(start, end);

    final content = file.openSync();
    try {
      content.setPositionSync(start0);
      yield* content.read(length).asStream();
    } finally {
      content.closeSync();
    }
  }

  (int, int, int) cleanRange(int start, int end) {
    final length = contentLength;
    if (start >= length) {
      return (0, contentLength - 1, contentLength);
    }

    final realEnd = min(end, length - 1);
    final realLength = realEnd - start + 1;

    return (start, realEnd, realLength);
  }

  @override
  ReadOnlyHeaders headers(ReadOnlyHeaders? requestHeaders) {
    final stat = file.statSync();
    final headers = MutableHeadersImpl()
      ..lastModified = stat.modified
      ..filename = p.basename(file.path)
      ..mimeType = mimeType
      ..acceptRanges = 'bytes';

    if (requestHeaders?.range case final range?) {
      final (start, end) = range;
      final (realStart, realEnd, realLength) = cleanRange(start, end);

      headers
        ..range = (realStart, realEnd)
        ..contentLength = realLength;
    } else {
      headers.contentLength = contentLength;
    }

    return headers;
  }
}
