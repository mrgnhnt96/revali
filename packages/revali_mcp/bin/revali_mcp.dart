import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

/// Minimal MCP stdio server (JSON-RPC + Content-Length framing).
///
/// Buffering is done in **bytes**, not decoded characters: `Content-Length`
/// counts bytes, so a body containing any non-ASCII character (`é` is two
/// bytes but one code unit) would otherwise look shorter than the header
/// promised and the server would wait forever for data that already arrived.
Future<void> main() async {
  final root = Directory.current.path;
  final buffer = BytesBuilder();

  await for (final chunk in stdin) {
    buffer.add(chunk);
    var bytes = buffer.takeBytes();

    while (true) {
      final header = _findHeaderEnd(bytes);
      if (header == null) break;

      final contentLength = _contentLengthOf(bytes, header.start);
      if (contentLength == null) {
        // A header block with no usable Content-Length can never complete.
        // Drop it and resynchronise instead of stalling on it forever.
        bytes = bytes.sublist(header.end);
        continue;
      }

      if (bytes.length - header.end < contentLength) break;

      final message = utf8.decode(
        bytes.sublist(header.end, header.end + contentLength),
      );
      bytes = bytes.sublist(header.end + contentLength);

      await _handleMessage(message, root);
    }

    buffer.add(bytes);
  }
}

/// Locates the blank line terminating the header block, tolerating bare LF.
///
/// Returns where the headers stop (`start`) and where the body begins
/// (`end`), or null while the terminator has not arrived yet.
({int start, int end})? _findHeaderEnd(List<int> bytes) {
  const cr = 0x0D;
  const lf = 0x0A;

  for (var i = 0; i + 1 < bytes.length; i++) {
    if (bytes[i] == cr &&
        i + 3 < bytes.length &&
        bytes[i + 1] == lf &&
        bytes[i + 2] == cr &&
        bytes[i + 3] == lf) {
      return (start: i, end: i + 4);
    }

    if (bytes[i] == lf && bytes[i + 1] == lf) {
      return (start: i, end: i + 2);
    }
  }

  return null;
}

/// Reads `Content-Length` out of the header block. Headers are ASCII, so
/// decoding them ahead of the body is safe.
int? _contentLengthOf(List<int> bytes, int headerLength) {
  final header = latin1.decode(
    bytes.sublist(0, headerLength),
    allowInvalid: true,
  );

  for (final line in header.split(RegExp(r'\r?\n'))) {
    final separator = line.indexOf(':');
    if (separator < 0) continue;
    if (line.substring(0, separator).trim().toLowerCase() != 'content-length') {
      continue;
    }

    return int.tryParse(line.substring(separator + 1).trim());
  }

  return null;
}

Future<void> _handleMessage(String raw, String root) async {
  Map<String, dynamic> msg;
  try {
    msg = jsonDecode(raw) as Map<String, dynamic>;
  } catch (_) {
    return;
  }

  final id = msg['id'];
  final method = msg['method'] as String?;
  if (method == null) return;

  switch (method) {
    case 'initialize':
      _respond(id, {
        'protocolVersion': '2024-11-05',
        'capabilities': {'tools': <String, Object>{}},
        'serverInfo': {'name': 'revali_mcp', 'version': '0.1.0'},
      });
    case 'notifications/initialized':
      return;
    case 'tools/list':
      _respond(id, {'tools': _tools});
    case 'tools/call':
      final params =
          msg['params'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final name = params['name'] as String? ?? '';
      final args =
          (params['arguments'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final text = await _callTool(name, args, root);
      _respond(id, {
        'content': [
          {'type': 'text', 'text': text},
        ],
      });
    case 'ping':
      _respond(id, {});
    default:
      if (id != null) {
        _respondError(id, -32601, 'Method not found: $method');
      }
  }
}

void _respond(Object? id, Object result) {
  _send({'jsonrpc': '2.0', 'id': id, 'result': result});
}

void _respondError(Object? id, int code, String message) {
  _send({
    'jsonrpc': '2.0',
    'id': id,
    'error': {'code': code, 'message': message},
  });
}

/// Writes one framed message.
///
/// The body goes out as bytes rather than via `stdout.write`, which would
/// re-encode using [Stdout.encoding] -- not necessarily UTF-8, and so not
/// necessarily the length already announced in the header.
void _send(Map<String, Object?> payload) {
  final bytes = utf8.encode(jsonEncode(payload));

  stdout
    ..add(utf8.encode('Content-Length: ${bytes.length}\r\n\r\n'))
    ..add(bytes);
}

final _tools = [
  {
    'name': 'list_routes',
    'description':
        'List routes from .revali/server/routes.json (optional regenerate)',
    'inputSchema': {
      'type': 'object',
      'properties': {
        'generate': {
          'type': 'boolean',
          'description': 'Run dart run revali routes --generate first',
        },
      },
    },
  },
  {
    'name': 'get_route',
    'description': 'Find a route by method/path or handler name',
    'inputSchema': {
      'type': 'object',
      'properties': {
        'method': {'type': 'string'},
        'path': {'type': 'string'},
        'handler': {'type': 'string'},
      },
    },
  },
  {
    'name': 'doctor',
    'description': 'Run revali doctor --json',
    'inputSchema': <String, Object>{
      'type': 'object',
      'properties': <String, Object>{},
    },
  },
  {
    'name': 'recent_requests',
    'description':
        'Read last N lines from .revali/inspect/requests.jsonl '
        '(requires revali dev --inspect)',
    'inputSchema': {
      'type': 'object',
      'properties': {
        'limit': {'type': 'integer', 'description': 'Max lines (default 20)'},
      },
    },
  },
  {
    'name': 'create_scaffold',
    'description': 'Run dart run revali create <type> …',
    'inputSchema': {
      'type': 'object',
      'properties': {
        'type': {
          'type': 'string',
          'description':
              'controller | app | lifecycle-component | pipe | observer',
        },
        'name': {'type': 'string'},
        'args': {
          'type': 'array',
          'items': {'type': 'string'},
          'description': 'Extra CLI args',
        },
      },
      'required': ['type'],
    },
  },
];

Future<String> _callTool(
  String name,
  Map<String, dynamic> args,
  String root,
) async {
  switch (name) {
    case 'list_routes':
      if (args['generate'] == true) {
        await _run(root, ['run', 'revali', 'routes', '--generate', '--json']);
      }
      final file = File(p.join(root, '.revali', 'server', 'routes.json'));
      if (!file.existsSync()) {
        return 'No routes.json at ${file.path}. Generate first.';
      }
      return file.readAsStringSync();
    case 'get_route':
      final file = File(p.join(root, '.revali', 'server', 'routes.json'));
      if (!file.existsSync()) {
        return 'No routes.json';
      }
      final decoded =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final routes = (decoded['routes'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();
      final method = (args['method'] as String?)?.toUpperCase();
      final path = args['path'] as String?;
      final handler = args['handler'] as String?;
      final matches = routes.where((r) {
        if (method != null &&
            (r['method'] as String?)?.toUpperCase() != method) {
          return false;
        }
        final routePath = r['path'] as String? ?? '';
        if (path != null && routePath != path && !routePath.contains(path)) {
          return false;
        }
        final routeHandler = r['handler'] as String? ?? '';
        if (handler != null &&
            routeHandler != handler &&
            !routeHandler.contains(handler)) {
          return false;
        }
        return method != null || path != null || handler != null;
      }).toList();
      return const JsonEncoder.withIndent('  ').convert(matches);
    case 'doctor':
      return _run(root, ['run', 'revali', 'doctor', '--json']);
    case 'recent_requests':
      final file = File(p.join(root, '.revali', 'inspect', 'requests.jsonl'));
      if (!file.existsSync()) {
        return 'No inspect log at ${file.path}. '
            'Start the server with `dart run revali dev --inspect`.';
      }
      final limit = (args['limit'] as num?)?.toInt() ?? 20;
      final lines = file.readAsLinesSync();
      final slice = lines.length <= limit
          ? lines
          : lines.sublist(lines.length - limit);
      return slice.join('\n');
    case 'create_scaffold':
      final type = args['type'] as String? ?? 'controller';
      final name = args['name'] as String?;
      final extra = (args['args'] as List<dynamic>?)?.cast<String>() ?? [];
      final cmd = [
        'run',
        'revali',
        'create',
        type,
        if (name != null) ...['--name', name],
        ...extra,
      ];
      return _run(root, cmd);
    default:
      return 'Unknown tool: $name';
  }
}

Future<String> _run(String root, List<String> args) async {
  final result = await Process.run(
    'dart',
    args,
    workingDirectory: root,
    runInShell: true,
  );
  final out = StringBuffer()
    ..write(result.stdout)
    ..write(result.stderr);
  if (result.exitCode != 0) {
    out.writeln('\n(exit ${result.exitCode})');
  }
  return out.toString().trim();
}
