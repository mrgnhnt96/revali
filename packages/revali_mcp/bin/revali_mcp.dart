import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Minimal MCP stdio server (JSON-RPC + Content-Length framing).
Future<void> main() async {
  final root = Directory.current.path;
  final buffer = StringBuffer();
  var contentLength = 0;
  var inHeaders = true;

  await for (final chunk in stdin.transform(utf8.decoder)) {
    buffer.write(chunk);
    while (true) {
      final data = buffer.toString();
      if (inHeaders) {
        final sep = data.indexOf('\r\n\r\n');
        final sepLf = sep < 0 ? data.indexOf('\n\n') : -1;
        final sep2 = sep >= 0 ? sep : sepLf;
        if (sep2 < 0) break;
        final headerBlock = data.substring(0, sep2);
        final headerEnd = sep >= 0 ? sep2 + 4 : sep2 + 2;
        contentLength = 0;
        for (final line in headerBlock.split(RegExp(r'\r?\n'))) {
          final lower = line.toLowerCase();
          if (lower.startsWith('content-length:')) {
            contentLength = int.parse(line.split(':').last.trim());
          }
        }
        buffer
          ..clear()
          ..write(data.substring(headerEnd));
        inHeaders = false;
      }

      if (!inHeaders) {
        final body = buffer.toString();
        if (body.length < contentLength) break;
        final message = body.substring(0, contentLength);
        buffer
          ..clear()
          ..write(body.substring(contentLength));
        inHeaders = true;
        await _handleMessage(message, root);
      }
    }
  }
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
  final payload = jsonEncode({'jsonrpc': '2.0', 'id': id, 'result': result});
  final bytes = utf8.encode(payload);
  stdout
    ..write('Content-Length: ${bytes.length}\r\n\r\n')
    ..write(payload);
}

void _respondError(Object? id, int code, String message) {
  final payload = jsonEncode({
    'jsonrpc': '2.0',
    'id': id,
    'error': {'code': code, 'message': message},
  });
  final bytes = utf8.encode(payload);
  stdout
    ..write('Content-Length: ${bytes.length}\r\n\r\n')
    ..write(payload);
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
    'description': 'Run dart run revali_server create <type> …',
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
        'revali_server',
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
