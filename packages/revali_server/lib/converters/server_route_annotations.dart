import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_router_core/revali_router_core.dart';
import 'package:revali_server/revali_server.dart';

class ServerRouteAnnotations with ExtractImport {
  ServerRouteAnnotations({
    required this.coreMimics,
    required this.coreTypeReferences,
    required this.data,
    required this.combine,
    required this.meta,
    required this.setHeaders,
    required this.allowOrigins,
  });

  factory ServerRouteAnnotations.fromApp(MetaAppConfig app) {
    return ServerRouteAnnotations._fromGetter(app.annotationsFor);
  }
  factory ServerRouteAnnotations.fromParent(MetaRoute parent) {
    return ServerRouteAnnotations._fromGetter(parent.annotationsFor);
  }

  factory ServerRouteAnnotations.fromRoute(MetaMethod method) {
    return ServerRouteAnnotations._fromGetter(method.annotationsMapper);
  }

  factory ServerRouteAnnotations._fromGetter(AnnotationMapper getter) {
    final mimics = _AnnotationMimics();
    final types = _AnnotationTypeReferences();

    final data = <ServerMimic>[];
    final setHeaders = <ServerSetHeader>[];
    final combine = <ServerMimic>[];
    final meta = <ServerMimic>[];
    final allowOrigins = <ServerAllowOrigin>[];

    getter(
      onMatch: [
        OnMatch(
          classType: Middleware,
          package: 'revali_router',
          convert: (object, annotation) {
            mimics.middlewares
                .add(ServerMimic.fromDartObject(object, annotation));
          },
        ),
        OnMatch(
          classType: Interceptor,
          package: 'revali_router',
          convert: (object, annotation) {
            mimics.interceptors
                .add(ServerMimic.fromDartObject(object, annotation));
          },
        ),
        OnMatch(
          classType: ExceptionCatcher,
          package: 'revali_router',
          ignoreGenerics: true,
          convert: (object, annotation) {
            mimics.catchers.add(ServerMimic.fromDartObject(object, annotation));
          },
        ),
        OnMatch(
          classType: Catches,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            types.catchers.add(
              ServerTypeReference.fromElement(object,
                  superType: ExceptionCatcher),
            );
          },
        ),
        OnMatch(
          classType: Uses,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            types.middlewares.add(
                ServerTypeReference.fromElement(object, superType: Middleware));
          },
        ),
        OnMatch(
          classType: Intercepts,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            types.interceptors.add(
              ServerTypeReference.fromElement(object, superType: Interceptor),
            );
          },
        ),
        OnMatch(
          classType: Guards,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            types.guards.add(
              ServerTypeReference.fromElement(object, superType: Guard),
            );
          },
        ),
        OnMatch(
          classType: Guard,
          package: 'revali_router',
          convert: (object, annotation) {
            mimics.guards.add(ServerMimic.fromDartObject(object, annotation));
          },
        ),
        OnMatch(
          classType: Data,
          package: 'revali_router',
          ignoreGenerics: true,
          convert: (object, annotation) {
            data.add(ServerMimic.fromDartObject(object, annotation));
          },
        ),
        OnMatch(
          classType: CombineMeta,
          package: 'revali_router',
          convert: (object, annotation) {
            combine.add(ServerMimic.fromDartObject(object, annotation));
          },
        ),
        OnMatch(
          classType: Meta,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            meta.add(ServerMimic.fromDartObject(object, annotation));
          },
        ),
        OnMatch(
          classType: SetHeader,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            setHeaders.add(ServerSetHeader.fromDartObject(object));
          },
        ),
        OnMatch(
          classType: AllowOrigins,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            allowOrigins.add(ServerAllowOrigin.fromDartObject(object));
          },
        ),
      ],
    );

    return ServerRouteAnnotations(
      coreMimics: mimics,
      coreTypeReferences: types,
      data: data,
      combine: combine,
      meta: meta,
      setHeaders: setHeaders,
      allowOrigins: allowOrigins,
    );
  }

  final _AnnotationTypeReferences coreTypeReferences;
  final _AnnotationMimics coreMimics;
  final Iterable<ServerMimic> data;
  final Iterable<ServerMimic> combine;
  final Iterable<ServerMimic> meta;
  final Iterable<ServerSetHeader> setHeaders;
  final Iterable<ServerAllowOrigin> allowOrigins;

  bool get hasAnnotations {
    if (coreMimics.all.isNotEmpty) return true;
    if (coreTypeReferences.all.isNotEmpty) return true;
    if (data.isNotEmpty) return true;
    if (combine.isNotEmpty) return true;
    if (meta.isNotEmpty) return true;
    if (setHeaders.isNotEmpty) return true;
    if (allowOrigins.isNotEmpty) return true;
    return false;
  }

  @override
  List<ExtractImport?> get extractors => [
        ...coreMimics.all,
        ...coreTypeReferences.all,
        ...data,
        ...combine,
        ...meta,
      ];

  @override
  List<ServerImports?> get imports => const [];
}

abstract class BaseAnnotations<T> {
  Iterable<T> get middlewares;
  Iterable<T> get interceptors;
  Iterable<T> get catchers;
  Iterable<T> get guards;
}

class _AnnotationTypeReferences
    implements BaseAnnotations<ServerTypeReference> {
  @override
  List<ServerTypeReference> catchers = [];

  @override
  List<ServerTypeReference> guards = [];

  @override
  List<ServerTypeReference> interceptors = [];

  @override
  List<ServerTypeReference> middlewares = [];

  Iterable<ServerTypeReference> get all => [
        ...middlewares,
        ...interceptors,
        ...catchers,
        ...guards,
      ];
}

class _AnnotationMimics implements BaseAnnotations<ServerMimic> {
  @override
  List<ServerMimic> catchers = [];

  @override
  List<ServerMimic> guards = [];

  @override
  List<ServerMimic> interceptors = [];

  @override
  List<ServerMimic> middlewares = [];

  Iterable<ServerMimic> get all => [
        ...middlewares,
        ...interceptors,
        ...catchers,
        ...guards,
      ];
}
