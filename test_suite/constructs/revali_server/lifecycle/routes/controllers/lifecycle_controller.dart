import 'package:revali_router/revali_router.dart';

@Controller('lifecycle')
class LifecycleController {
  const LifecycleController();

  /// Reports what the ambient [TraceContext] holds, so a test can check the
  /// router populated it from the inbound request.
  @Get('trace')
  Map<String, Object?> trace() {
    final trace = TraceContext.current;

    return {
      'requestId': trace?.requestId,
      'traceparent': trace?.traceparent,
      'baggage': trace?.baggage,
    };
  }

  /// Reads the context only after an await, where a zone that did not cover
  /// the whole request would have been lost.
  @Get('trace-async')
  Future<String?> traceAsync() async {
    await Future<void>.delayed(Duration.zero);

    return TraceContext.current?.requestId;
  }

  @Get('boom')
  String boom() {
    throw const HttpError.conflict(code: 'already_exists', message: 'Taken');
  }
}
