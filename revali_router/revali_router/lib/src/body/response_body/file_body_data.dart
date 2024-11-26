part of 'base_body_data.dart';

final class FileBodyData extends BaseBodyData<io.File> {
  FileBodyData(super.data);

  @visibleForTesting
  static FileSystem fs = const LocalFileSystem();

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
      return;
    }

    final bytes = _bytes = data.readAsBytesSync();
    yield* Stream.value(bytes);
  }

  File? _file;
  File get file {
    if (_file case final file?) {
      return file;
    }

    final path = fs.file(data.path).resolveSymbolicLinksSync();

    return _file = fs.file(path);
  }

  Stream<List<int>> range(int start, int? end) async* {
    final (start0, end0, _) = cleanRange(start, end);
    final length = end0 - start0 + 1;

    final content = file.openSync();
    try {
      content.setPositionSync(start0);
      yield* content.read(length).asStream();
    } finally {
      content.closeSync();
    }
  }

  (int, int, int) cleanRange(int start, int? end) {
    final length = data.lengthSync();
    if (start >= length) {
      return (0, length - 1, length);
    }

    final realEnd = switch (end) {
      int() => min(end, length - 1),
      _ => length - 1,
    };

    return (start, realEnd, length);
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
        ..contentRange = (realStart, realEnd, realLength)
        ..contentLength = realEnd - realStart + 1
        ..mimeType = 'application/octet-stream';
    } else {
      headers.contentLength = contentLength;
    }

    return headers;
  }
}
