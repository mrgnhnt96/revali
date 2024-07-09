import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_shelf/converters/shelf_mimic.dart';
import 'package:revali_shelf/converters/shelf_set_header.dart';
import 'package:revali_shelf/converters/shelf_type_reference.dart';

class ShelfRouteAnnotations {
  const ShelfRouteAnnotations({
    required this.mimics,
    required this.typeReferences,
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
    final mimics = _AnnotationMimics();
    final types = _AnnotationTypeReferences();

    final data = <ShelfMimic>[];
    final setHeaders = <ShelfSetHeader>[];
    final combine = <ShelfMimic>[];
    final meta = <ShelfMimic>[];

    getter(
      onMatch: [
        OnMatch(
          classType: Middleware,
          package: 'revali_router',
          convert: (object, annotation) {
            mimics.middlewares
                .add(ShelfMimic.fromDartObject(object, annotation));
          },
        ),
        OnMatch(
          classType: Interceptor,
          package: 'revali_router',
          convert: (object, annotation) {
            mimics.interceptors
                .add(ShelfMimic.fromDartObject(object, annotation));
          },
        ),
        OnMatch(
          classType: ExceptionCatcher,
          package: 'revali_router',
          convert: (object, annotation) {
            mimics.catchers.add(ShelfMimic.fromDartObject(object, annotation));
          },
        ),
        OnMatch(
          classType: Catches,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            types.catchers.add(
              ShelfTypeReference.fromElement(object,
                  superType: ExceptionCatcher),
            );
          },
        ),
        OnMatch(
          classType: Uses,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            types.middlewares.add(
                ShelfTypeReference.fromElement(object, superType: Middleware));
          },
        ),
        OnMatch(
          classType: Intercepts,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            types.interceptors.add(
              ShelfTypeReference.fromElement(object, superType: Interceptor),
            );
          },
        ),
        OnMatch(
          classType: Guards,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            types.guards.add(
              ShelfTypeReference.fromElement(object, superType: Guard),
            );
          },
        ),
        OnMatch(
          classType: Guard,
          package: 'revali_router',
          convert: (object, annotation) {
            mimics.guards.add(ShelfMimic.fromDartObject(object, annotation));
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
      mimics: mimics,
      typeReferences: types,
      data: data,
      combine: combine,
      meta: meta,
      setHeaders: setHeaders,
    );
  }

  final _AnnotationTypeReferences typeReferences;
  final _AnnotationMimics mimics;
  final Iterable<ShelfMimic> data;
  final Iterable<ShelfMimic> combine;
  final Iterable<ShelfMimic> meta;
  final Iterable<ShelfSetHeader> setHeaders;

  Iterable<String> get imports sync* {
    final mimics = [
      ...this.mimics.all,
      ...data,
      ...combine,
      ...meta,
    ];

    for (final mimic in mimics) {
      yield* mimic.imports.imports;
    }

    for (final typeList in typeReferences.all) {
      yield* typeList.imports;
    }
  }
}

abstract class BaseAnnotations<T> {
  Iterable<T> get middlewares;
  Iterable<T> get interceptors;
  Iterable<T> get catchers;
  Iterable<T> get guards;
}

class _AnnotationTypeReferences implements BaseAnnotations<ShelfTypeReference> {
  @override
  List<ShelfTypeReference> catchers = [];

  @override
  List<ShelfTypeReference> guards = [];

  @override
  List<ShelfTypeReference> interceptors = [];

  @override
  List<ShelfTypeReference> middlewares = [];

  Iterable<ShelfTypeReference> get all => [
        ...middlewares,
        ...interceptors,
        ...catchers,
        ...guards,
      ];
}

class _AnnotationMimics implements BaseAnnotations<ShelfMimic> {
  @override
  List<ShelfMimic> catchers = [];

  @override
  List<ShelfMimic> guards = [];

  @override
  List<ShelfMimic> interceptors = [];

  @override
  List<ShelfMimic> middlewares = [];

  Iterable<ShelfMimic> get all => [
        ...middlewares,
        ...interceptors,
        ...catchers,
        ...guards,
      ];
}
