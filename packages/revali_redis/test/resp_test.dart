import 'dart:convert';
import 'dart:typed_data';

import 'package:revali_redis/revali_redis.dart';
import 'package:test/test.dart';

Uint8List bytes(String raw) => Uint8List.fromList(utf8.encode(raw));

Object? decodeAll(String raw) => decode(bytes(raw))?.value;

void main() {
  group('encodeCommand', () {
    test('encodes a command as an array of bulk strings', () {
      expect(utf8.decode(encodeCommand(['PING'])), '*1\r\n\$4\r\nPING\r\n');
    });

    test('encodes several arguments', () {
      expect(
        utf8.decode(encodeCommand(['XACK', 'orders', 'billing'])),
        '*3\r\n\$4\r\nXACK\r\n\$6\r\norders\r\n\$7\r\nbilling\r\n',
      );
    });

    test('counts bytes, not characters', () {
      // A multi-byte argument counts for more than its length in code units.
      // Getting this wrong leaves the connection desynchronised rather than
      // failing outright, which is far harder to diagnose.
      final encoded = utf8.decode(encodeCommand(['SET', 'k', 'é']));

      expect(encoded, contains('\$2\r\né\r\n'));
    });

    test('handles an empty argument', () {
      expect(utf8.decode(encodeCommand([''])), '*1\r\n\$0\r\n\r\n');
    });
  });

  group('decode', () {
    test('reads a simple string', () {
      expect(decodeAll('+OK\r\n'), 'OK');
    });

    test('reads an integer', () {
      expect(decodeAll(':42\r\n'), 42);
    });

    test('reads a bulk string', () {
      expect(decodeAll('\$5\r\nhello\r\n'), 'hello');
    });

    test('reads an empty bulk string', () {
      expect(decodeAll('\$0\r\n\r\n'), '');
    });

    test('reads a null bulk string', () {
      // What XREADGROUP returns when its block expires with no work.
      expect(decodeAll('\$-1\r\n'), isNull);
    });

    test('reads a null array', () {
      expect(decodeAll('*-1\r\n'), isNull);
    });

    test('reads an array', () {
      expect(decodeAll('*2\r\n\$3\r\nfoo\r\n\$3\r\nbar\r\n'), ['foo', 'bar']);
    });

    test('reads nested arrays', () {
      // The shape XREADGROUP actually replies with.
      expect(decodeAll('*1\r\n*2\r\n\$6\r\norders\r\n*1\r\n\$3\r\nabc\r\n'), [
        [
          'orders',
          ['abc'],
        ],
      ]);
    });

    test('reads a bulk string containing CRLF', () {
      // Length-prefixed, so the delimiter inside the payload must not end it.
      expect(decodeAll('\$4\r\na\r\nb\r\n'), 'a\r\nb');
    });

    test('reads multi-byte content by byte length', () {
      expect(decodeAll('\$2\r\né\r\n'), 'é');
    });

    test('throws on an error reply', () {
      expect(
        () => decodeAll('-ERR bad command\r\n'),
        throwsA(isA<RedisError>()),
      );
    });

    test('recognises BUSYGROUP as the already-exists reply', () {
      // Every start after the first says this; treating it as a failure would
      // make a restart fatal.
      try {
        decodeAll('-BUSYGROUP Consumer Group name already exists\r\n');
        fail('should have thrown');
      } on RedisError catch (e) {
        expect(e.isBusyGroup, isTrue);
      }
    });

    test('does not mistake another error for BUSYGROUP', () {
      expect(const RedisError('ERR no such key').isBusyGroup, isFalse);
    });

    test('throws on an unknown reply type', () {
      expect(() => decodeAll('%1\r\n'), throwsA(isA<RedisError>()));
    });
  });

  group('partial replies', () {
    test('returns null when the terminator has not arrived', () {
      expect(decode(bytes('+OK')), isNull);
    });

    test('returns null when a bulk body is incomplete', () {
      // A reply split across packets is routine for a large XREADGROUP batch;
      // decoding it as if complete would corrupt the stream.
      expect(decode(bytes('\$5\r\nhel')), isNull);
    });

    test('returns null when an array is incomplete', () {
      expect(decode(bytes('*2\r\n\$3\r\nfoo\r\n')), isNull);
    });

    test('reports how many bytes one reply consumed', () {
      final reply = decode(bytes('+OK\r\n+SECOND\r\n'));

      expect(reply?.value, 'OK');
      // The caller advances by this to find the next reply.
      expect(reply?.length, 5);
    });

    test('decodes the second reply from an offset', () {
      final buffer = bytes('+OK\r\n+SECOND\r\n');
      final first = decode(buffer)!;

      expect(decode(buffer, first.length)?.value, 'SECOND');
    });
  });
}
