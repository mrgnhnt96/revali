import 'dart:convert';
import 'dart:typed_data';

/// An error reply from Redis.
class RedisError implements Exception {
  const RedisError(this.message);

  final String message;

  /// Whether this is the "group already exists" reply.
  ///
  /// Creating a consumer group is the only sane way to make subscribing
  /// idempotent, and every start after the first says this. It is a success,
  /// not a failure.
  bool get isBusyGroup => message.startsWith('BUSYGROUP');

  /// Whether the stream or consumer group has gone.
  ///
  /// Redis answers `NOGROUP` when a group `XREADGROUP` names no longer
  /// exists. A server restart without persistence is the ordinary way that
  /// happens: the connection comes back fine, so nothing looks broken, and
  /// every subsequent read fails against a group nobody will recreate.
  bool get isNoGroup => message.startsWith('NOGROUP');

  @override
  String toString() => 'RedisError: $message';
}

/// Encodes a command as a RESP array of bulk strings.
///
/// Everything Redis accepts as a command is this shape, so there is no need
/// for the other request forms.
List<int> encodeCommand(List<String> parts) {
  final buffer = StringBuffer('*${parts.length}\r\n');

  for (final part in parts) {
    // Length is in **bytes**, not characters: a multi-byte argument counts
    // for more than its length in code units, and getting this wrong leaves
    // the connection desynchronised rather than failing outright.
    buffer.write('\$${utf8.encode(part).length}\r\n$part\r\n');
  }

  return utf8.encode(buffer.toString());
}

/// One decoded reply, plus how many bytes it consumed.
class RespValue {
  const RespValue(this.value, this.length);

  /// A `String`, `int`, `List<Object?>`, or null for a null bulk/array.
  final Object? value;

  /// Bytes consumed from the buffer.
  final int length;
}

/// Decodes one reply from [bytes] at [offset].
///
/// Returns null when the buffer does not yet hold a complete reply — the
/// caller keeps reading and tries again. Streaming decoders that instead
/// assume a whole reply per socket chunk break the moment a reply is split
/// across packets, which happens under exactly the load that matters.
RespValue? decode(Uint8List bytes, [int offset = 0]) {
  if (offset >= bytes.length) {
    return null;
  }

  final lineEnd = _findCrlf(bytes, offset);
  if (lineEnd == null) {
    return null;
  }

  final type = bytes[offset];
  final line = utf8.decode(bytes.sublist(offset + 1, lineEnd));
  final headerLength = lineEnd + 2 - offset;

  switch (type) {
    // + simple string
    case 0x2b:
      return RespValue(line, headerLength);
    // - error
    case 0x2d:
      throw RedisError(line);
    // : integer
    case 0x3a:
      return RespValue(int.parse(line), headerLength);
    // $ bulk string
    case 0x24:
      final size = int.parse(line);
      if (size == -1) {
        return RespValue(null, headerLength);
      }

      final end = offset + headerLength + size + 2;
      if (end > bytes.length) {
        return null;
      }

      return RespValue(
        utf8.decode(bytes.sublist(offset + headerLength, end - 2)),
        end - offset,
      );
    // * array
    case 0x2a:
      final count = int.parse(line);
      if (count == -1) {
        return RespValue(null, headerLength);
      }

      final items = <Object?>[];
      var cursor = offset + headerLength;

      for (var i = 0; i < count; i++) {
        final item = decode(bytes, cursor);
        if (item == null) {
          return null;
        }

        items.add(item.value);
        cursor += item.length;
      }

      return RespValue(items, cursor - offset);
    default:
      throw RedisError('Unknown reply type: ${String.fromCharCode(type)}');
  }
}

int? _findCrlf(Uint8List bytes, int from) {
  for (var i = from; i + 1 < bytes.length; i++) {
    if (bytes[i] == 0x0d && bytes[i + 1] == 0x0a) {
      return i;
    }
  }

  return null;
}
