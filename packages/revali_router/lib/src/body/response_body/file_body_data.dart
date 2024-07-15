part of 'base_body_data.dart';

final class FileBodyData extends BaseBodyData<File> {
  FileBodyData(super.data);

  String? _mimeType;
  @override
  String? get mimeType {
    return _mimeType ??= lookupMimeType(file.path);
  }

  int? _length;
  @override
  int get contentLength {
    return _length ??= data.lengthSync();
  }

  List<int>? _bytes;
  @override
  Stream<List<int>> read() async* {
    if (_bytes case final bytes?) {
      yield* Stream.fromIterable([bytes]);
    }
    final bytes = _bytes = await data.readAsBytesSync();

    yield* Stream.fromIterable([bytes]);
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
    final (_start, _, _length) = cleanRange(start, end);

    final content = file.openSync();
    try {
      content.setPositionSync(_start);
      yield* content.read(_length).asStream();
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

  ReadOnlyHeaders headers(ReadOnlyHeaders? requestHeaders) {
    final stat = file.statSync();
    final headers = MutableHeadersImpl();

    if (requestHeaders?.range case final range?) {
      final (start, end) = range;
      final (realStart, realEnd, realLength) = cleanRange(start, end);

      headers[HttpHeaders.contentRangeHeader] =
          'bytes $realStart-$realEnd/$contentLength';
      headers[HttpHeaders.contentLengthHeader] = '$realLength';
    } else {
      headers[HttpHeaders.contentLengthHeader] = '$contentLength';
    }
    if (mimeType case final value?) {
      headers[HttpHeaders.contentTypeHeader] = value;
    }

    headers[HttpHeaders.lastModifiedHeader] = HttpDate.format(stat.modified);
    headers[HttpHeaders.contentDisposition] = [
      'attachment',
      'filename=${Uri.encodeComponent(p.basename(file.path))}',
    ].join('; ');
    headers[HttpHeaders.acceptRangesHeader] = 'bytes';

    return headers;
  }
}
