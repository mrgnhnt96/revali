import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_shelf/converters/shelf_mimic.dart';
import 'package:revali_shelf/converters/shelf_set_header.dart';

class ShelfRouteAnnotations {
  const ShelfRouteAnnotations({
    required this.middlewares,
    required this.interceptors,
    required this.catchers,
    required this.guards,
    required this.data,
    required this.combine,
    required this.meta,
    required this.setHeaders,
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
    final setHeaders = <ShelfSetHeader>[];

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
        OnMatch(
          classType: Meta,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            meta.add(ShelfMimic.fromDartObject(object, annotation));
          },
        ),
        OnMatch(
          classType: SetHeader,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            setHeaders.add(ShelfSetHeader.fromDartObject(object));
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
      combine: combine,
      meta: meta,
      setHeaders: setHeaders,
    );
  }

  final Iterable<ShelfMimic> middlewares;
  final Iterable<ShelfMimic> interceptors;
  final Iterable<ShelfMimic> catchers;
  final Iterable<ShelfMimic> guards;
  final Iterable<ShelfMimic> data;
  final Iterable<ShelfMimic> combine;
  final Iterable<ShelfMimic> meta;
  final Iterable<ShelfSetHeader> setHeaders;

  Iterable<String> get imports sync* {
    final mimics = [
      ...middlewares,
      ...interceptors,
      ...catchers,
      ...guards,
      ...data,
      ...combine,
      ...meta,
    ];

    for (final mimic in mimics) {
      yield* mimic.imports.imports;
    }
  }
}
