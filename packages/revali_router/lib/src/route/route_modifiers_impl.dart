import 'package:revali_router/revali_router.dart';
import 'package:revali_router_core/revali_router_core.dart';

class RouteModifiersImpl implements RouteModifiers {
  RouteModifiersImpl({
    List<Middleware>? middlewares,
    List<Interceptor>? interceptors,
    List<Guard>? guards,
    List<ExceptionCatcher>? catchers,
    void Function(MetaHandler)? meta,
    List<CombineMeta> combine = const [],
    Set<String>? allowedOrigins,
    Set<String>? allowedHeaders,
  })  : _meta = meta,
        middlewares = middlewares ?? [],
        interceptors = interceptors ?? [],
        guards = guards ?? [],
        catchers = catchers ?? [],
        allowedOrigins = allowedOrigins ?? {},
        allowedHeaders = allowedHeaders ?? {} {
    CombineMetaApplier(this, combine).apply();
  }

  final List<Middleware> middlewares;
  final List<Interceptor> interceptors;
  final List<ExceptionCatcher> catchers;
  final List<Guard> guards;
  final void Function(MetaHandler)? _meta;
  final Set<String> allowedOrigins;
  final Set<String> allowedHeaders;

  MetaHandler getMeta({MetaHandler? handler}) {
    final meta = handler ?? MetaHandler();

    _meta?.call(meta);

    return meta;
  }
}
