import 'package:revali_router/revali_router.dart';

class RouteModifiers {
  RouteModifiers({
    List<Middleware>? middlewares,
    List<Interceptor>? interceptors,
    List<Guard>? guards,
    List<ExceptionCatcher>? catchers,
    void Function(MetaHandler)? meta,
    List<CombineMeta> combine = const [],
  })  : _meta = meta,
        middlewares = middlewares ?? [],
        interceptors = interceptors ?? [],
        guards = guards ?? [],
        catchers = catchers ?? [] {
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
