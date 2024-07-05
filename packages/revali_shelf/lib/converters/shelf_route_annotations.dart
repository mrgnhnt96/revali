import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_shelf/revali_shelf.dart';

class ShelfRouteAnnotations {
  const ShelfRouteAnnotations({
    required this.middlewares,
    required this.interceptors,
    required this.catchers,
    required this.guards,
    required this.data,
    required this.combine,
    required this.meta,
  });

  factory ShelfRouteAnnotations.fromParent(MetaRoute parent) {
    return ShelfRouteAnnotations._fromGetter(parent.annotationsFor);
  }
  factory ShelfRouteAnnotations.fromRoute(MetaMethod method) {
    return ShelfRouteAnnotations._fromGetter(method.annotationsMapper);
  }

  factory ShelfRouteAnnotations._fromGetter(AnnotationMapper getter) {
    final middlewares = <ShelfClass>[];
    final interceptors = <ShelfClass>[];
    final catchers = <ShelfClass>[];
    final guards = <ShelfClass>[];
    final data = <ShelfClass>[];
    final apply = <ShelfClass>[];
    final meta = <ShelfSetMeta>[];

    getter(
      on: [
        OnClass(
          classType: Middleware,
          package: 'revali_router',
          convert: (annotation, source) {
            middlewares.add(ShelfClass.fromDartObject(annotation, source));
          },
        ),
        OnClass(
          classType: Interceptor,
          package: 'revali_router',
          convert: (annotation, source) {
            interceptors.add(ShelfClass.fromDartObject(annotation, source));
          },
        ),
        OnClass(
          classType: ExceptionCatcher,
          package: 'revali_router',
          convert: (annotation, source) {
            catchers.add(ShelfClass.fromDartObject(annotation, source));
          },
        ),
        // will implement later
        // OnClass(
        //   classType: Catches,
        //   package: 'revali_router',
        //   convert: (annotation, source) {
        //     final catches = ShelfCatches.fromDartObject(annotation);
        //     catchers.addAll(catches.catchers);
        //   },
        // ),
        OnClass(
          classType: Guard,
          package: 'revali_router',
          convert: (annotation, source) {
            guards.add(ShelfClass.fromDartObject(annotation, source));
          },
        ),
        OnClass(
          classType: Data,
          package: 'revali_router',
          convert: (annotation, source) {
            data.add(ShelfClass.fromDartObject(annotation, source));
          },
        ),
        OnClass(
          classType: CombineMeta,
          package: 'revali_router',
          convert: (annotation, source) {
            apply.add(ShelfClass.fromDartObject(annotation, source));
          },
        ),
        OnClass(
          classType: SetMeta,
          package: 'revali_router_annotations',
          convert: (annotation, source) {
            meta.add(ShelfSetMeta.fromDartObject(annotation, source));
          },
        ),
      ],
    );

    return ShelfRouteAnnotations(
      middlewares: middlewares,
      interceptors: interceptors,
      catchers: catchers,
      guards: guards,
      data: data,
      combine: apply,
      meta: meta,
    );
  }

  final Iterable<ShelfClass> middlewares;
  final Iterable<ShelfClass> interceptors;
  final Iterable<ShelfClass> catchers;
  final Iterable<ShelfClass> guards;
  final Iterable<ShelfClass> data;
  final Iterable<ShelfClass> combine;
  final Iterable<ShelfSetMeta> meta;
}
