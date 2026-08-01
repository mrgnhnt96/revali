import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Concurrent HTTP load generator against the playground server.
///
/// Usage:
///   dart run bin/stress.dart [--base http://127.0.0.1:8090] [--concurrency 200]
///     [--duration 30s] [--mix all|ping|delay|error|heavy]
Future<void> main(List<String> args) async {
  final base = _arg(args, '--base') ?? 'http://127.0.0.1:8090';
  final concurrency = int.parse(_arg(args, '--concurrency') ?? '100');
  final duration = _parseDuration(_arg(args, '--duration') ?? '20s');
  final mix = _arg(args, '--mix') ?? 'all';
  final prefix = '$base/api/stress';

  final client = HttpClient()
    ..maxConnectionsPerHost = concurrency
    ..idleTimeout = const Duration(seconds: 5)
    ..connectionTimeout = const Duration(seconds: 5);

  final endpoints = switch (mix) {
    'ping' => [() => _get(client, '$prefix/ping')],
    'delay' => [() => _get(client, '$prefix/delay?ms=25')],
    'error' => [
      () => _get(client, '$prefix/error'),
      () => _get(client, '$prefix/async-error'),
    ],
    'heavy' => [
      () => _get(client, '$prefix/cpu?n=50000'),
      () => _get(client, '$prefix/large?kb=256'),
      () => _get(client, '$prefix/alloc?kb=128'),
      () => _postJson(client, '$prefix/echo', {'n': Random().nextInt(1 << 20)}),
    ],
    _ => [
      () => _get(client, '$prefix/ping'),
      () => _get(client, '$prefix/count'),
      () => _get(client, '$prefix/delay?ms=10'),
      () => _get(client, '$prefix/cpu?n=5000'),
      () => _get(client, '$prefix/path/${Random().nextInt(10000)}'),
      () => _get(client, '$prefix/large?kb=32'),
      () => _get(client, '$prefix/error'),
      () => _get(client, '$prefix/async-error'),
      () => _postJson(client, '$prefix/echo', {
        'hello': 'world',
        'i': Random().nextInt(100000),
      }),
      () => _postBytes(client, '$prefix/bytes', Random().nextInt(64) + 1),
    ],
  };

  stdout.writeln(
    'Stressing $base  concurrency=$concurrency  '
    'duration=${duration.inSeconds}s  mix=$mix',
  );

  final stopAt = DateTime.now().add(duration);
  final stats = _Stats();
  final workers = <Future<void>>[];
  final ticker = Timer.periodic(const Duration(seconds: 2), (_) {
    stdout.writeln(stats.snapshot());
  });

  for (var i = 0; i < concurrency; i++) {
    workers.add(() async {
      final rng = Random(i);
      while (DateTime.now().isBefore(stopAt)) {
        final call = endpoints[rng.nextInt(endpoints.length)];
        final sw = Stopwatch()..start();
        try {
          final code = await call();
          sw.stop();
          stats.record(code, sw.elapsedMicroseconds);
        } catch (e) {
          sw.stop();
          stats.recordError(e, sw.elapsedMicroseconds);
        }
      }
    }());
  }

  await Future.wait(workers);
  ticker.cancel();
  client.close(force: true);

  stdout
    ..writeln('\n=== FINAL ===')
    ..writeln(stats.snapshot(final_: true));

  final intentionalErrors = mix == 'all' || mix == 'error';
  if (stats.clientExceptions > 0) {
    exitCode = 2;
  } else if (!intentionalErrors && stats.status5xx > stats.ok * 0.05) {
    exitCode = 2;
  }
}

Future<int> _get(HttpClient client, String url) async {
  final req = await client.getUrl(Uri.parse(url));
  final res = await req.close().timeout(const Duration(seconds: 30));
  await res.drain<void>();
  return res.statusCode;
}

Future<int> _postJson(
  HttpClient client,
  String url,
  Map<String, Object?> body,
) async {
  final req = await client.postUrl(Uri.parse(url));
  req.headers.contentType = ContentType.json;
  req.add(utf8.encode(jsonEncode(body)));
  final res = await req.close().timeout(const Duration(seconds: 30));
  await res.drain<void>();
  return res.statusCode;
}

Future<int> _postBytes(HttpClient client, String url, int kb) async {
  final req = await client.postUrl(Uri.parse(url));
  req.headers.contentType = ContentType.binary;
  req.add(List.filled(kb * 1024, 7));
  final res = await req.close().timeout(const Duration(seconds: 30));
  await res.drain<void>();
  return res.statusCode;
}

String? _arg(List<String> args, String name) {
  final i = args.indexOf(name);
  if (i == -1 || i + 1 >= args.length) return null;
  return args[i + 1];
}

Duration _parseDuration(String raw) {
  if (raw.endsWith('ms')) {
    return Duration(milliseconds: int.parse(raw.substring(0, raw.length - 2)));
  }
  if (raw.endsWith('s')) {
    return Duration(seconds: int.parse(raw.substring(0, raw.length - 1)));
  }
  if (raw.endsWith('m')) {
    return Duration(minutes: int.parse(raw.substring(0, raw.length - 1)));
  }
  return Duration(seconds: int.parse(raw));
}

class _Stats {
  int ok = 0;
  int status4xx = 0;
  int status5xx = 0;
  int clientExceptions = 0;
  int samples = 0;
  int totalUs = 0;
  final Map<String, int> errors = {};

  void record(int code, int us) {
    samples++;
    totalUs += us;
    if (code >= 200 && code < 400) {
      ok++;
    } else if (code >= 400 && code < 500) {
      status4xx++;
    } else {
      status5xx++;
    }
  }

  void recordError(Object e, int us) {
    samples++;
    totalUs += us;
    clientExceptions++;
    final key = e.runtimeType.toString();
    errors[key] = (errors[key] ?? 0) + 1;
  }

  String snapshot({bool final_ = false}) {
    final avgMs = samples == 0 ? 0 : (totalUs / samples) / 1000;
    final errSummary = errors.entries
        .map((e) => '${e.key}:${e.value}')
        .join(',');
    return '${final_ ? "FINAL " : ""}'
        'ok=$ok 4xx=$status4xx 5xx=$status5xx '
        'clientErr=$clientExceptions avgMs=${avgMs.toStringAsFixed(1)} '
        'n=$samples'
        '${errSummary.isEmpty ? "" : " errors={$errSummary}"}';
  }
}
