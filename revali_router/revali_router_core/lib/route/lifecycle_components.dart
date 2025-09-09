import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_router_core/components/exception_catcher.dart';
import 'package:revali_router_core/components/guard.dart';
import 'package:revali_router_core/components/interceptor.dart';
import 'package:revali_router_core/components/middleware.dart';
import 'package:revali_router_core/meta/meta_handler.dart';
import 'package:revali_router_core/response_handler/response_handler.dart';

abstract class LifecycleComponents {
  const LifecycleComponents();

  List<Middleware> get middlewares;
  List<Interceptor> get interceptors;
  // ignore: strict_raw_type
  List<ExceptionCatcher> get catchers;
  List<Guard> get guards;
  void Function(MetaHandler)? get _meta;
  AllowOrigins? get allowedOrigins;
  AllowHeaders? get allowedHeaders;
  ExpectHeaders? get expectedHeaders;
  ResponseHandler? get responseHandler;

  MetaHandler getMeta({MetaHandler? handler}) {
    final meta = handler ?? MetaHandler();

    _meta?.call(meta);

    return meta;
  }
}
