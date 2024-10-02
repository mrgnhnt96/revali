import 'package:revali_router_core/exception_catcher/exception_catcher.dart';
import 'package:revali_router_core/guard/guard.dart';
import 'package:revali_router_core/interceptor/interceptor.dart';
import 'package:revali_router_core/middleware/middleware.dart';

abstract interface class CombineComponents {
  const CombineComponents({
    this.guards = const [],
    this.middlewares = const [],
    this.interceptors = const [],
    this.catchers = const [],
  });

  final Iterable<Guard> guards;
  final Iterable<Middleware> middlewares;
  final Iterable<Interceptor> interceptors;
  final Iterable<ExceptionCatcher> catchers;
}
