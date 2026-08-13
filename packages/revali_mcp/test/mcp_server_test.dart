import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';

/// Drives `bin/revali_mcp.dart` over stdio the way an MCP client does.
class McpClient {
  McpClient._(this._process, this._responses);

  static Future<McpClient> start() async {
    final process = await Process.start('dart', [
      'run',
      'bin/revali_mcp.dart',
    ], workingDirectory: Directory.current.path);

    // Parse Content-Length framing off the server's stdout.
    final responses = StreamController<Map<String, dynamic>>();
    final buffer = BytesBuilder();

    process.stdout.listen((chunk) {
      buffer.add(chunk);
      var bytes = buffer.takeBytes();

      while (true) {
        final text = latin1.decode(bytes, allowInvalid: true);
        final sep = text.indexOf('\r\n\r\n');
        if (sep < 0) break;

        final header = text.substring(0, sep);
        final match = RegExp(
          r'content-length:\s*(\d+)',
          caseSensitive: false,
        ).firstMatch(header);
        if (match == null) break;

        final length = int.parse(match.group(1)!);
        final start = sep + 4;
        if (bytes.length - start < length) break;

        final body = utf8.decode(bytes.sublist(start, start + length));
        responses.add(jsonDecode(body) as Map<String, dynamic>);
        bytes = bytes.sublist(start + length);
      }

      buffer.add(bytes);
    });

    return McpClient._(process, responses.stream.asBroadcastStream());
  }

  final Process _process;
  final Stream<Map<String, dynamic>> _responses;

  Future<Map<String, dynamic>> request(
    Object? id,
    String method, [
    Map<String, dynamic>? params,
  ]) {
    final next = _responses.firstWhere((r) => r['id'] == id);

    final payload = jsonEncode({
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      if (params != null) 'params': params,
    });
    final bytes = utf8.encode(payload);

    // Content-Length is a BYTE count, per the spec.
    _process.stdin
      ..add(utf8.encode('Content-Length: ${bytes.length}\r\n\r\n'))
      ..add(bytes);

    return next.timeout(
      const Duration(seconds: 20),
      onTimeout: () => throw StateError('no response to "$method" (id: $id)'),
    );
  }

  Future<void> stop() async {
    await _process.stdin.close();
    _process.kill();
  }
}

void main() {
  late McpClient client;

  setUp(() async {
    client = await McpClient.start();
  });

  tearDown(() async {
    await client.stop();
  });

  test('responds to initialize', () async {
    final response = await client.request(1, 'initialize');

    expect(response['result'], isA<Map<String, dynamic>>());
    expect((response['result'] as Map)['protocolVersion'], '2024-11-05');
    expect(
      ((response['result'] as Map)['serverInfo'] as Map)['name'],
      'revali_mcp',
    );
  });

  test('lists its tools', () async {
    await client.request(1, 'initialize');
    final response = await client.request(2, 'tools/list');

    final tools = (response['result'] as Map)['tools'] as List;
    final names = tools.map((t) => (t as Map)['name']).toList();

    expect(names, containsAll(<String>['list_routes', 'get_route', 'doctor']));
  });

  test('answers ping', () async {
    await client.request(1, 'initialize');

    expect(await client.request(2, 'ping'), containsPair('result', isEmpty));
  });

  test('reports unknown methods as JSON-RPC errors', () async {
    await client.request(1, 'initialize');
    final response = await client.request(2, 'nope/does-not-exist');

    expect((response['error'] as Map)['code'], -32601);
  });

  test('handles two messages delivered in one chunk', () async {
    // Framing must not assume one write == one message.
    final first = client.request(1, 'initialize');
    final second = client.request(2, 'ping');

    await first;
    await second;
  });

  test('handles a message body containing non-ASCII', () async {
    await client.request(1, 'initialize');

    // Regression: the server used to buffer decoded characters and compare
    // their count against Content-Length, which is a byte count. "é" is two
    // bytes but one code unit, so any non-ASCII body left the server waiting
    // on data that had already arrived, and it never replied at all.
    final response = await client.request(2, 'tools/call', {
      'name': 'get_route',
      'arguments': {'handler': 'café-héllo-wörld'},
    });

    expect(response['result'], isNotNull);
  });
}
