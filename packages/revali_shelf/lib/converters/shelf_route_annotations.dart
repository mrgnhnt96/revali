import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_shelf/converters/shelf_mimic.dart';
import 'package:revali_shelf/converters/shelf_set_header.dart';
import 'package:revali_shelf/converters/shelf_types_list.dart';

class ShelfRouteAnnotations {
  const ShelfRouteAnnotations({
    required this.middlewares,
    required this.interceptors,
    required this.catchers,
    required this.guardsMimic,
    required this.data,
    required this.combine,
    required this.meta,
    required this.setHeaders,
    required this.catches,
    required this.uses,
    required this.intercepts,
    required this.guards,
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
    final guardsMimic = <ShelfMimic>[];
    final data = <ShelfMimic>[];
    final combine = <ShelfMimic>[];
    final meta = <ShelfMimic>[];
    final setHeaders = <ShelfSetHeader>[];
    final catches = <ShelfTypesList>[];
    final uses = <ShelfTypesList>[];
    final intercepts = <ShelfTypesList>[];
    final guards = <ShelfTypesList>[];

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
        OnMatch(
          classType: Catches,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            catches.add(
              ShelfTypesList.fromElement(object, superType: ExceptionCatcher),
            );
          },
        ),
        OnMatch(
          classType: Uses,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            uses.add(ShelfTypesList.fromElement(object, superType: Middleware));
          },
        ),
        OnMatch(
          classType: Intercepts,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            intercepts.add(
              ShelfTypesList.fromElement(object, superType: Interceptor),
            );
          },
        ),
        OnMatch(
          classType: Guards,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            guards.add(
              ShelfTypesList.fromElement(object, superType: Guard),
            );
          },
        ),
        OnMatch(
          classType: Guard,
          package: 'revali_router',
          convert: (object, annotation) {
            guardsMimic.add(ShelfMimic.fromDartObject(object, annotation));
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
      guardsMimic: guardsMimic,
      data: data,
      combine: combine,
      meta: meta,
      setHeaders: setHeaders,
      catches: catches,
      uses: uses,
      intercepts: intercepts,
      guards: guards,
    );
  }

  final Iterable<ShelfMimic> middlewares;
  final Iterable<ShelfMimic> interceptors;
  final Iterable<ShelfMimic> catchers;
  final Iterable<ShelfMimic> guardsMimic;
  final Iterable<ShelfMimic> data;
  final Iterable<ShelfMimic> combine;
  final Iterable<ShelfMimic> meta;
  final Iterable<ShelfSetHeader> setHeaders;
  final Iterable<ShelfTypesList> catches;
  final Iterable<ShelfTypesList> uses;
  final Iterable<ShelfTypesList> intercepts;
  final Iterable<ShelfTypesList> guards;

  Iterable<String> get imports sync* {
    final mimics = [
      ...middlewares,
      ...interceptors,
      ...catchers,
      ...guardsMimic,
      ...data,
      ...combine,
      ...meta,
    ];

    final typeLists = [
      ...catches,
      ...uses,
      ...intercepts,
      ...guards,
    ];

    for (final mimic in mimics) {
      yield* mimic.imports.imports;
    }

    for (final typeList in typeLists) {
      yield* typeList.imports;
    }
  }
}
