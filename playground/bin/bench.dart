import 'dart:convert';
import 'dart:io';

/// Stable ping benchmark for the playground server.
///
/// Uses `bin/stress.dart` by default; pass `--ab` to try ApacheBench.
///
/// Usage:
///   dart run bin/bench.dart [--label baseline] [--base http://127.0.0.1:8090]
///     [--concurrency 300] [--requests 60000] [--duration 15s]
Future<void> main(List<String> args) async {
  final label = _arg(args, '--label') ?? 'run';
  final base = _arg(args, '--base') ?? 'http://127.0.0.1:8090';
  final concurrency = int.parse(_arg(args, '--concurrency') ?? '300');
  final requests = int.parse(_arg(args, '--requests') ?? '60000');
  final duration = _arg(args, '--duration') ?? '15s';
  final url = '$base/api/stress/ping';

  stdout.writeln(
    'bench label=$label url=$url concurrency=$concurrency '
    'requests=$requests duration=$duration',
  );

  // Warmup — discard.
  await _warm(url);

  // Prefer the Dart stress client: ApacheBench often times out against
  // multi-isolate `shared: true` listeners on macOS.
  final preferAb = args.contains('--ab');
  final ab = preferAb ? await _which('ab') : null;
  final BenchResult result;
  if (ab != null) {
    result = await _runAb(
      ab: ab,
      url: url,
      concurrency: concurrency,
      requests: requests,
    );
  } else {
    result = await _runStress(
      base: base,
      concurrency: concurrency,
      duration: duration,
    );
  }

  stdout
    ..writeln()
    ..writeln('=== BENCH RESULT ===')
    ..writeln(result.toMarkdownRow(label))
    ..writeln()
    ..writeln(result.toPretty())
    // Machine-readable line for scripts / BENCHMARKS.md append.
    ..writeln('BENCH_JSON ${jsonEncode(result.toJson(label))}');
}

Future<void> _warm(String url) async {
  final client = HttpClient();
  try {
    for (var i = 0; i < 200; i++) {
      final req = await client.getUrl(Uri.parse(url));
      final res = await req.close();
      await res.drain<void>();
    }
  } finally {
    client.close(force: true);
  }
}

Future<BenchResult> _runAb({
  required String ab,
  required String url,
  required int concurrency,
  required int requests,
}) async {
  final proc = await Process.run(ab, [
    '-n',
    '$requests',
    '-c',
    '$concurrency',
    '-s',
    '60',
    url,
  ]);
  final out = '${proc.stdout}\n${proc.stderr}';
  if (proc.exitCode != 0) {
    stderr.writeln(out);
    throw StateError('ab failed with exit ${proc.exitCode}');
  }

  double? rps;
  double? meanMs;
  double? p50;
  double? p95;
  double? p99;
  int? completed;
  int? failed;

  for (final line in out.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.startsWith('Requests per second:')) {
      rps = double.parse(trimmed.split(RegExp(r'\s+'))[3]);
    } else if (trimmed.startsWith('Time per request:') &&
        trimmed.contains('(mean)')) {
      meanMs = double.parse(trimmed.split(RegExp(r'\s+'))[3]);
    } else if (trimmed.startsWith('Complete requests:')) {
      completed = int.parse(trimmed.split(RegExp(r'\s+')).last);
    } else if (trimmed.startsWith('Failed requests:')) {
      failed = int.parse(trimmed.split(RegExp(r'\s+')).last);
    } else if (trimmed.startsWith('50%')) {
      p50 = double.parse(trimmed.split(RegExp(r'\s+')).last);
    } else if (trimmed.startsWith('95%')) {
      p95 = double.parse(trimmed.split(RegExp(r'\s+')).last);
    } else if (trimmed.startsWith('99%')) {
      p99 = double.parse(trimmed.split(RegExp(r'\s+')).last);
    }
  }

  return BenchResult(
    tool: 'ab',
    rps: rps ?? 0,
    meanMs: meanMs ?? 0,
    p50Ms: p50,
    p95Ms: p95,
    p99Ms: p99,
    completed: completed ?? requests,
    failed: failed ?? 0,
    concurrency: concurrency,
  );
}

Future<BenchResult> _runStress({
  required String base,
  required int concurrency,
  required String duration,
}) async {
  final proc = await Process.run('dart', [
    'run',
    'bin/stress.dart',
    '--base',
    base,
    '--concurrency',
    '$concurrency',
    '--duration',
    duration,
    '--mix',
    'ping',
  ], workingDirectory: Directory.current.path);
  final out = '${proc.stdout}\n${proc.stderr}';
  stdout.writeln(out);

  final finalLine = out
      .split('\n')
      .map((l) => l.trim())
      .firstWhere((l) => l.startsWith('FINAL '), orElse: () => '');
  final rpsLine = out
      .split('\n')
      .map((l) => l.trim())
      .firstWhere((l) => l.startsWith('rps='), orElse: () => '');
  final okMatch = RegExp(r'ok=(\d+)').firstMatch(finalLine);
  final avgMatch = RegExp(r'avgMs=([\d.]+)').firstMatch(finalLine);
  final errMatch = RegExp(r'clientErr=(\d+)').firstMatch(finalLine);
  final p50Match = RegExp(r'p50=([\d.]+)').firstMatch(finalLine);
  final p95Match = RegExp(r'p95=([\d.]+)').firstMatch(finalLine);
  final p99Match = RegExp(r'p99=([\d.]+)').firstMatch(finalLine);
  final rpsMatch = RegExp(r'rps=([\d.]+)').firstMatch(rpsLine);
  final ok = int.parse(okMatch?.group(1) ?? '0');
  final avgMs = double.parse(avgMatch?.group(1) ?? '0');
  final clientErr = int.parse(errMatch?.group(1) ?? '0');
  final rps = double.parse(rpsMatch?.group(1) ?? '0');

  return BenchResult(
    tool: 'stress',
    rps: rps,
    meanMs: avgMs,
    p50Ms: p50Match == null ? null : double.parse(p50Match.group(1)!),
    p95Ms: p95Match == null ? null : double.parse(p95Match.group(1)!),
    p99Ms: p99Match == null ? null : double.parse(p99Match.group(1)!),
    completed: ok,
    failed: clientErr,
    concurrency: concurrency,
  );
}

Future<String?> _which(String name) async {
  final proc = await Process.run('which', [name]);
  if (proc.exitCode != 0) return null;
  final path = (proc.stdout as String).trim();
  return path.isEmpty ? null : path;
}

String? _arg(List<String> args, String name) {
  final i = args.indexOf(name);
  if (i == -1 || i + 1 >= args.length) return null;
  return args[i + 1];
}

class BenchResult {
  BenchResult({
    required this.tool,
    required this.rps,
    required this.meanMs,
    required this.completed,
    required this.failed,
    required this.concurrency,
    this.p50Ms,
    this.p95Ms,
    this.p99Ms,
  });

  final String tool;
  final double rps;
  final double meanMs;
  final double? p50Ms;
  final double? p95Ms;
  final double? p99Ms;
  final int completed;
  final int failed;
  final int concurrency;

  Map<String, Object?> toJson(String label) => {
    'label': label,
    'tool': tool,
    'rps': double.parse(rps.toStringAsFixed(1)),
    'meanMs': double.parse(meanMs.toStringAsFixed(2)),
    'p50Ms': p50Ms,
    'p95Ms': p95Ms,
    'p99Ms': p99Ms,
    'completed': completed,
    'failed': failed,
    'concurrency': concurrency,
  };

  String toPretty() {
    final buf = StringBuffer()
      ..writeln(
        'tool=$tool  rps=${rps.toStringAsFixed(1)}  '
        'meanMs=${meanMs.toStringAsFixed(2)}  '
        'completed=$completed  failed=$failed  c=$concurrency',
      );
    if (p50Ms != null) {
      buf.writeln(
        'latency p50=${p50Ms!.toStringAsFixed(0)}ms  '
        'p95=${p95Ms?.toStringAsFixed(0)}ms  '
        'p99=${p99Ms?.toStringAsFixed(0)}ms',
      );
    }
    return buf.toString();
  }

  String toMarkdownRow(String label) {
    final p50 = p50Ms?.toStringAsFixed(0) ?? '—';
    final p95 = p95Ms?.toStringAsFixed(0) ?? '—';
    final p99 = p99Ms?.toStringAsFixed(0) ?? '—';
    return '| $label | ${rps.toStringAsFixed(0)} | '
        '${meanMs.toStringAsFixed(1)} | $p50 | $p95 | $p99 | '
        '$failed | $tool |';
  }
}
