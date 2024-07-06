import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_shelf/converters/shelf_mimic.dart';

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
    final middlewares = <ShelfMimic>[];
    final interceptors = <ShelfMimic>[];
    final catchers = <ShelfMimic>[];
    final guards = <ShelfMimic>[];
    final data = <ShelfMimic>[];
    final combine = <ShelfMimic>[];
    final meta = <ShelfMimic>[];

    getter(
      onMatch: [
        OnMatch(
          classType: Middleware,
          package: 'revali_router',
          convert: (object, annotation) {
            middlewares.add(ShelfMimic.fromDartObject(object, annotation));
          },
        ),
        OnMatch(
          classType: Interceptor,
          package: 'revali_router',
          convert: (object, annotation) {
            interceptors.add(ShelfMimic.fromDartObject(object, annotation));
          },
        ),
        OnMatch(
          classType: ExceptionCatcher,
          package: 'revali_router',
          convert: (object, annotation) {
            catchers.add(ShelfMimic.fromDartObject(object, annotation));
          },
        ),
        // will implement later
        // OnClass(
        //   classType: Catches,
        //   package: 'revali_router',
        //   convert: (object, annotation) {
        //     final catches = ShelfCatches.fromDartObject(object);
        //     catchers.addAll(catches.catchers);
        //   },
        // ),
        OnMatch(
          classType: Guard,
          package: 'revali_router',
          convert: (object, annotation) {
            guards.add(ShelfMimic.fromDartObject(object, annotation));
          },
        ),
        OnMatch(
          classType: Data,
          package: 'revali_router',
          convert: (object, annotation) {
            data.add(ShelfMimic.fromDartObject(object, annotation));
          },
        ),
        OnMatch(
          classType: CombineMeta,
          package: 'revali_router',
          convert: (object, annotation) {
            combine.add(ShelfMimic.fromDartObject(object, annotation));
          },
        ),
      ],
      onNonMatch: NonMatch(
        ignore: [
          Matcher.any('Method'),
          Matcher.any('Controller'),
        ],
        convert: (object, annotation) {
          meta.add(ShelfMimic.fromDartObject(object, annotation));
        },
      ),
    );

    return ShelfRouteAnnotations(
      middlewares: middlewares,
      interceptors: interceptors,
      catchers: catchers,
      guards: guards,
      data: data,
      combine: combine,
      meta: meta,
    );
  }

  final Iterable<ShelfMimic> middlewares;
  final Iterable<ShelfMimic> interceptors;
  final Iterable<ShelfMimic> catchers;
  final Iterable<ShelfMimic> guards;
  final Iterable<ShelfMimic> data;
  final Iterable<ShelfMimic> combine;
  final Iterable<ShelfMimic> meta;
}
