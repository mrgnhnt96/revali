import 'package:revali_router_core/exception_catcher/exception_catcher.dart';
import 'package:revali_router_core/guard/guard.dart';
import 'package:revali_router_core/interceptor/interceptor.dart';
import 'package:revali_router_core/middleware/middleware.dart';

abstract interface class CombineMeta {
  const CombineMeta({
    this.guards = const [],
    this.middlewares = const [],
    this.interceptors = const [],
    this.catchers = const [],
  });

  final List<Guard> guards;
  final List<Middleware> middlewares;
  final List<Interceptor> interceptors;
  final List<ExceptionCatcher> catchers;
}
