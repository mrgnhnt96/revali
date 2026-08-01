import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:revali_router/revali_router.dart';

/// Endpoints designed to exercise weak points under load.
@Controller('stress')
class StressController {
  StressController();

  static final _rng = Random();
  static int _counter = 0;
  static final Map<String, List<int>> _leaky = {};

  @Get('ping')
  String ping() => 'pong';

  @Get('count')
  Map<String, int> count() {
    _counter++;
    return {'count': _counter};
  }

  @Get('cpu')
  Map<String, Object> cpu(@Query('n') String? n) {
    final iterations = int.tryParse(n ?? '') ?? 10000;
    var acc = 0;
    for (var i = 0; i < iterations; i++) {
      acc ^= _rng.nextInt(1 << 30);
    }
    return {'acc': acc, 'n': iterations};
  }

  @Get('delay')
  Future<Map<String, Object>> delay(@Query('ms') String? ms) async {
    final delayMs = int.tryParse(ms ?? '') ?? 50;
    await Future<void>.delayed(Duration(milliseconds: delayMs));
    return {'delayedMs': delayMs};
  }

  @Post('echo')
  Future<Map<String, Object?>> echo(@Body() Map<String, dynamic>? body) async {
    return {'keys': body?.keys.length ?? 0, 'echo': body};
  }

  @Post('bytes')
  Future<Map<String, int>> bytes(@Body() List<int>? body) async {
    return {'bytes': body?.length ?? 0};
  }

  @Get('large')
  Map<String, Object> large(@Query('kb') String? kb) {
    final sizeKb = (int.tryParse(kb ?? '') ?? 64).clamp(1, 8192);
    final payload = List.filled(sizeKb * 1024, 65); // 'A'
    return {'size': payload.length, 'data': utf8.decode(payload)};
  }

  @Get('alloc')
  Map<String, Object> alloc(@Query('kb') String? kb) {
    // Intentionally retains allocations across requests to pressure GC/heap.
    final sizeKb = (int.tryParse(kb ?? '') ?? 256).clamp(1, 4096);
    final key = DateTime.now().microsecondsSinceEpoch.toString();
    _leaky[key] = List.filled(sizeKb * 1024, 1);
    if (_leaky.length > 200) {
      final oldest = _leaky.keys.first;
      _leaky.remove(oldest);
    }
    return {'retainedKeys': _leaky.length, 'kb': sizeKb};
  }

  @Get('error')
  String error() {
    throw StateError('intentional stress error');
  }

  @Get('async-error')
  Future<String> asyncError() async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    throw StateError('intentional async stress error');
  }

  @Get('late-error')
  String lateError() {
    // Fire-and-forget that throws after the handler returns — exercises
    // the zone-guard warning path without crashing the accept loop.
    Future<void>.delayed(const Duration(milliseconds: 5), () {
      throw StateError('unawaited late error');
    }).ignore();
    return 'scheduled';
  }

  @Get('path/:id')
  Map<String, String> path(@Param('id') String id) => {'id': id};

  @SSE('events')
  Stream<String> events(@Query('n') String? n) async* {
    final count = (int.tryParse(n ?? '') ?? 5).clamp(1, 100);
    for (var i = 0; i < count; i++) {
      yield 'event-$i';
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }
}
