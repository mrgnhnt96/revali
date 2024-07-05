import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_shelf/revali_shelf.dart';

class ShelfRouteAnnotations {
  const ShelfRouteAnnotations({
    required this.middlewares,
    required this.interceptors,
    required this.catchers,
    required this.guards,
  });

  factory ShelfRouteAnnotations.fromParent(MetaRoute parent) {
    return ShelfRouteAnnotations._fromGetter(parent.annotationsFor);
  }
  factory ShelfRouteAnnotations.fromRoute(MetaMethod method) {
    return ShelfRouteAnnotations._fromGetter(method.annotationsFor);
  }

  factory ShelfRouteAnnotations._fromGetter(AnnotationGetter getter) {
    final middlewares = <ShelfMiddleware>[];
    final interceptors = <ShelfInterceptor>[];
    final catchers = <ShelfCatcher>[];
    final guards = <ShelfGuard>[];

    if (getter(
      classType: Middleware,
      package: 'revali_router',
    )
        case final annotations when annotations.isNotEmpty) {
      for (final annotation in annotations) {
        middlewares.add(ShelfMiddleware.fromDartObject(annotation));
      }
    }

    if (getter(
      classType: Interceptor,
      package: 'revali_router',
    )
        case final annotations when annotations.isNotEmpty) {
      for (final annotation in annotations) {
        interceptors.add(ShelfInterceptor.fromDartObject(annotation));
      }
    }

    if (getter(
      classType: ExceptionCatcher,
      package: 'revali_router',
    )
        case final annotations when annotations.isNotEmpty) {
      for (final annotation in annotations) {
        catchers.add(ShelfCatcher.fromDartObject(annotation));
      }
    }

    if (getter(
      classType: Guard,
      package: 'revali_router',
    )
        case final annotations when annotations.isNotEmpty) {
      for (final annotation in annotations) {
        guards.add(ShelfGuard.fromDartObject(annotation));
      }
    }

    return ShelfRouteAnnotations(
      middlewares: middlewares,
      interceptors: interceptors,
      catchers: catchers,
      guards: guards,
    );
  }

  final Iterable<ShelfMiddleware> middlewares;
  final Iterable<ShelfInterceptor> interceptors;
  final Iterable<ShelfCatcher> catchers;
  final Iterable<ShelfGuard> guards;
}
