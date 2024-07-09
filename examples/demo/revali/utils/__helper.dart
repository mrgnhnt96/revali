part of '../server.dart';

final class _CombineMeta implements CombineMeta {
  const _CombineMeta({
    this.guards = const [],
    this.middlewares = const [],
    this.interceptors = const [],
    this.catchers = const [],
  });

  @override
  final List<Guard> guards;

  @override
  final List<Middleware> middlewares;

  @override
  final List<Interceptor> interceptors;

  @override
  final List<ExceptionCatcher> catchers;
}
