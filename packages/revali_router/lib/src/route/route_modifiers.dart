import 'package:revali_router/revali_router.dart';

class RouteModifiers {
  RouteModifiers({
    this.middlewares = const [],
    this.interceptors = const [],
    this.guards = const [],
    this.catchers = const [],
    void Function(MetaHandler)? meta,
    List<CombineMeta> combine = const [],
  }) : _meta = meta {
    CombineMetaApplier(this, combine).apply();
  }

  final List<Middleware> middlewares;
  final List<Interceptor> interceptors;
  final List<ExceptionCatcher> catchers;
  final List<Guard> guards;
  final void Function(MetaHandler)? _meta;

  MetaHandler getMeta({MetaHandler? handler}) {
    final meta = handler ?? MetaHandler();

    _meta?.call(meta);

    return meta;
  }
}
