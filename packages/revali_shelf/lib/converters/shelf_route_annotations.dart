import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_shelf/converters/shelf_catches.dart';
import 'package:revali_shelf/revali_shelf.dart';

class ShelfRouteAnnotations {
  const ShelfRouteAnnotations({
    required this.middlewares,
    required this.interceptors,
    required this.catchers,
    required this.guards,
    required this.data,
    required this.combine,
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
    final catchers = <ShelfExceptionCatcher>[];
    final guards = <ShelfGuard>[];
    final data = <ShelfSetData>[];
    final apply = <ShelfCombineMeta>[];

    if (getter(
      classType: Middleware,
      package: 'revali_router',
    )
        case final annotations when annotations.isNotEmpty) {
      middlewares.addAll(annotations.map(ShelfMiddleware.fromDartObject));
    }

    if (getter(
      classType: Interceptor,
      package: 'revali_router',
    )
        case final annotations when annotations.isNotEmpty) {
      interceptors.addAll(annotations.map(ShelfInterceptor.fromDartObject));
    }

    if (getter(
      classType: ExceptionCatcher,
      package: 'revali_router',
    )
        case final annotations when annotations.isNotEmpty) {
      catchers.addAll(annotations.map(ShelfExceptionCatcher.fromDartObject));
    }
    if (getter(
      classType: Catches,
      package: 'revali_router',
    )
        case final annotations when annotations.isNotEmpty) {
      for (final annotation in annotations) {
        final catches = ShelfCatches.fromDartObject(annotation);
        catchers.addAll(catches.catchers);
      }
    }

    if (getter(
      classType: Guard,
      package: 'revali_router',
    )
        case final annotations when annotations.isNotEmpty) {
      guards.addAll(annotations.map(ShelfGuard.fromDartObject));
    }

    if (getter(
      classType: SetData,
      package: 'revali_router_annotations',
    )
        case final annotations when annotations.isNotEmpty) {
      data.addAll(annotations.map(ShelfSetData.fromDartObject));
    }

    if (getter(
      classType: CombineMeta,
      package: 'revali_router_annotations',
    )
        case final annotations when annotations.isNotEmpty) {
      apply.addAll(annotations.map(ShelfCombineMeta.fromDartObject));
    }

    return ShelfRouteAnnotations(
      middlewares: middlewares,
      interceptors: interceptors,
      catchers: catchers,
      guards: guards,
      data: data,
      combine: apply,
    );
  }

  final Iterable<ShelfMiddleware> middlewares;
  final Iterable<ShelfInterceptor> interceptors;
  final Iterable<ShelfExceptionCatcher> catchers;
  final Iterable<ShelfGuard> guards;
  final Iterable<ShelfSetData> data;
  final Iterable<ShelfCombineMeta> combine;
}
