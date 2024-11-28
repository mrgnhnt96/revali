import 'package:revali_router_core/exception_catcher/exception_catcher.dart';
import 'package:revali_router_core/guard/guard.dart';
import 'package:revali_router_core/interceptor/interceptor.dart';
import 'package:revali_router_core/middleware/middleware.dart';

abstract interface class CombineComponents {
  const CombineComponents();

  Iterable<Guard> get guards;
  Iterable<Middleware> get middlewares;
  Iterable<Interceptor> get interceptors;
  // ignore: strict_raw_type
  Iterable<ExceptionCatcher> get catchers;
}
