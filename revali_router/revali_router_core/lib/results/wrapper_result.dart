import 'package:revali_router_core/response/response.dart';
import 'package:revali_router_core/results/interceptor_pre_result.dart';

/// Continues the execute pipeline:
/// middleware → guards → interceptors → handler.
typedef NextResponse = Future<Response> Function();

/// Alias for analyzer/codegen detection
/// (like [InterceptorPreResult]).
typedef WrapperResult = Future<Response>;
