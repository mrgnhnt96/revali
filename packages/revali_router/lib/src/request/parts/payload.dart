import 'dart:async';
import 'dart:convert';

class Payload {
  Payload._(
    this._stream,
    this.encoding,
    this.contentLength,
  );

  factory Payload(Object? body, [Encoding? encoding]) {
    if (body is Payload) return body;

    if (body is String &&
        encoding == null &&
        !_isPlainAscii(utf8.encode(body), body.length)) {
      encoding = utf8;
    }

    final List<int>? encoded = switch (body) {
      String() => (encoding ?? utf8).encode(body),
      List<int>() => body,
      List() => body.cast(),
      null => [],
      Stream() => null,
      _ => throw ArgumentError(
          'Body must be a String, List<int>, or a Stream.',
        ),
    };

    final Stream<List<int>> stream = switch (body) {
      String() => Stream.fromIterable([encoded!]),
      null => Stream.fromIterable([encoded!]),
      List() => Stream.value(encoded!),
      Stream<List<int>>() => body,
      Stream() => body.cast(),
      _ => throw ArgumentError(
          'Body must be a String, List<int>, or a Stream.',
        ),
    };

    return Payload._(
      stream,
      encoding,
      encoded?.length,
    );
  }

  final Stream<List<int>> _stream;
  final Encoding? encoding;
  final int? contentLength;

  static bool _isPlainAscii(List<int> bytes, int codeUnits) {
    // Most non-ASCII code units will produce multiple bytes and make the text
    // longer.
    if (bytes.length != codeUnits) return false;

    // Non-ASCII code units between U+0080 and U+009F produce 8-bit characters
    // with the high bit set.
    return bytes.every((byte) => byte & 0x80 == 0);
  }

  List<int>? _bytes;
  Stream<List<int>> read() async* {
    if (_bytes != null) {
      yield _bytes!;
      return;
    }

    final bytes = await _stream.toList();

    _bytes = bytes.expand<int>((e) => e).toList();

    yield _bytes!;
  }

  Future<String> readAsString([Encoding? encoding]) {
    return (encoding ?? this.encoding ?? utf8).decodeStream(read());
  }
}
