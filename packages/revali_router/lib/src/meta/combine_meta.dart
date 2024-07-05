import 'package:revali_router/src/exception_catcher/exception_catcher.dart';
import 'package:revali_router/src/guard/guard.dart';
import 'package:revali_router/src/interceptor/interceptor.dart';
import 'package:revali_router/src/middleware/middleware.dart';

abstract class CombineMeta {
  const CombineMeta({
    this.guards = const [],
    this.middleware = const [],
    this.interceptors = const [],
    this.catchers = const [],
  });

  final List<Guard> guards;
  final List<Middleware> middleware;
  final List<Interceptor> interceptors;
  final List<ExceptionCatcher> catchers;
}
