import 'package:revali_router_core/components/exception_catcher.dart';
import 'package:revali_router_core/components/guard.dart';
import 'package:revali_router_core/components/interceptor.dart';
import 'package:revali_router_core/components/middleware.dart';

abstract interface class CombineComponents {
  const CombineComponents();

  Iterable<Guard> get guards;
  Iterable<Middleware> get middlewares;
  Iterable<Interceptor> get interceptors;
  // ignore: strict_raw_type
  Iterable<ExceptionCatcher> get catchers;
}
