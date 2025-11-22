import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_router/src/meta/combine_components_applier.dart';
import 'package:revali_router_core/revali_router_core.dart';

class LifecycleComponentsImpl implements LifecycleComponents {
  LifecycleComponentsImpl({
    List<Middleware>? middlewares,
    List<Interceptor>? interceptors,
    List<Guard>? guards,
    // ignore: strict_raw_type
    List<ExceptionCatcher>? catchers,
    void Function(Meta)? meta,
    List<CombineComponents> combine = const [],
    this.allowedOrigins,
    this.preventedHeaders,
    this.expectedHeaders,
    this.responseHandler,
  })  : _meta = meta,
        middlewares = middlewares ?? [],
        interceptors = interceptors ?? [],
        guards = guards ?? [],
        catchers = catchers ?? [] {
    CombineComponentsApplier(this, combine).apply();
  }

  @override
  final List<Middleware> middlewares;
  @override
  final List<Interceptor> interceptors;
  @override
  // ignore: strict_raw_type
  final List<ExceptionCatcher> catchers;
  @override
  final List<Guard> guards;
  final void Function(Meta)? _meta;
  @override
  final AllowOrigins? allowedOrigins;
  @override
  final PreventHeaders? preventedHeaders;
  @override
  final ExpectHeaders? expectedHeaders;
  @override
  final ResponseHandler? responseHandler;

  @override
  Meta getMeta({Meta? handler}) {
    final meta = handler ?? Meta();

    _meta?.call(meta);

    return meta;
  }
}
