import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_router_core/exception_catcher/exception_catcher.dart';
import 'package:revali_router_core/guard/guard.dart';
import 'package:revali_router_core/interceptor/interceptor.dart';
import 'package:revali_router_core/meta/meta_handler.dart';
import 'package:revali_router_core/middleware/middleware.dart';

abstract class LifecycleComponents {
  const LifecycleComponents();

  List<Middleware> get middlewares;
  List<Interceptor> get interceptors;
  List<ExceptionCatcher> get catchers;
  List<Guard> get guards;
  void Function(MetaHandler)? get _meta;
  AllowOrigins? get allowedOrigins;
  AllowHeaders? get allowedHeaders;

  MetaHandler getMeta({MetaHandler? handler}) {
    final meta = handler ?? MetaHandler();

    _meta?.call(meta);

    return meta;
  }
}
