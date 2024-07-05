import 'package:revali_router/revali_router.dart';

abstract class CombineMeta {
  const CombineMeta({
    this.guards = const [],
    this.middleware = const [],
    this.interceptors = const [],
    this.catchers = const [],
    this.data = const [],
  });

  final List<Guard> guards;
  final List<Middleware> middleware;
  final List<Interceptor> interceptors;
  final List<ExceptionCatcher> catchers;
  final List<Data> data;
}
