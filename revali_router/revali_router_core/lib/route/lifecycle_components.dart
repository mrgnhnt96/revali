import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_router_core/components/exception_catcher.dart';
import 'package:revali_router_core/components/guard.dart';
import 'package:revali_router_core/components/interceptor.dart';
import 'package:revali_router_core/components/middleware.dart';
import 'package:revali_router_core/meta/meta.dart';
import 'package:revali_router_core/response_handler/response_handler.dart';

abstract class LifecycleComponents {
  const LifecycleComponents();

  List<Middleware> get middlewares;
  List<Interceptor> get interceptors;
  // ignore: strict_raw_type
  List<ExceptionCatcher> get catchers;
  List<Guard> get guards;
  void Function(Meta)? get _meta;
  AllowOrigins? get allowedOrigins;
  PreventHeaders? get preventedHeaders;
  ExpectHeaders? get expectedHeaders;
  ResponseHandler? get responseHandler;

  Meta getMeta({Meta? handler}) {
    final meta = handler ?? Meta();

    _meta?.call(meta);

    return meta;
  }
}
