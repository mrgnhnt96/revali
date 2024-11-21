// ignore_for_file: library_private_types_in_public_api

import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/revali_server.dart';

class ServerRouteAnnotations with ExtractImport {
  ServerRouteAnnotations({
    required this.coreMimics,
    required this.coreTypeReferences,
    required this.data,
    required this.meta,
    required this.setHeaders,
    required this.allowOrigins,
    required this.allowHeaders,
    required this.expectHeaders,
    required ServerMimic? responseHandler,
  }) : _responseHandler = responseHandler;

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
    final meta = <ServerMimic>[];
    ServerAllowOrigins? allowOrigins;
    ServerAllowHeaders? allowHeaders;
    ServerExpectHeaders? expectHeaders;
    ServerMimic? responseHandler;

    getter(
      onMatch: [
        OnMatch(
          classType: Middleware,
          package: 'revali_router_core',
          convert: (object, annotation) {
            mimics.middlewares
                .add(ServerMimic.fromDartObject(object, annotation));
          },
        ),
        OnMatch(
          classType: Interceptor,
          package: 'revali_router_core',
          convert: (object, annotation) {
            mimics.interceptors
                .add(ServerMimic.fromDartObject(object, annotation));
          },
        ),
        OnMatch(
          classType: ExceptionCatcher,
          package: 'revali_router_core',
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
              ServerTypeReference.fromElement(
                object,
                superType: ExceptionCatcher,
              ),
            );
          },
        ),
        OnMatch(
          classType: Middlewares,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            types.middlewares.add(
              ServerTypeReference.fromElement(object, superType: Middleware),
            );
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
          package: 'revali_router_core',
          convert: (object, annotation) {
            mimics.guards.add(ServerMimic.fromDartObject(object, annotation));
          },
        ),
        OnMatch(
          classType: CombineComponents,
          package: 'revali_router_core',
          convert: (object, annotation) {
            mimics.combines.add(ServerMimic.fromDartObject(object, annotation));
          },
        ),
        OnMatch(
          classType: Combines,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            types.combines.add(
              ServerTypeReference.fromElement(
                object,
                superType: CombineComponents,
              ),
            );
          },
        ),
        OnMatch(
          classType: Data,
          package: 'revali_router_core',
          ignoreGenerics: true,
          convert: (object, annotation) {
            data.add(ServerMimic.fromDartObject(object, annotation));
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
          package: 'revali_annotations',
          convert: (object, annotation) {
            if (allowOrigins != null) {
              throw ArgumentError(
                'Only one $AllowOrigins annotation is allowed',
              );
            }
            allowOrigins = ServerAllowOrigins.fromDartObject(object);
          },
        ),
        OnMatch(
          classType: AllowHeaders,
          package: 'revali_annotations',
          convert: (object, annotation) {
            if (allowHeaders != null) {
              throw ArgumentError(
                'Only one $AllowHeaders annotation is allowed',
              );
            }
            allowHeaders = ServerAllowHeaders.fromDartObject(object);
          },
        ),
        OnMatch(
          classType: ExpectHeaders,
          package: 'revali_annotations',
          convert: (object, annotation) {
            if (expectHeaders != null) {
              throw ArgumentError(
                'Only one $ExpectHeaders annotation is allowed',
              );
            }
            expectHeaders = ServerExpectHeaders.fromDartObject(object);
          },
        ),
        OnMatch(
          classType: ResponseHandler,
          package: 'revali_router_core',
          convert: (object, annotation) {
            if (responseHandler != null) {
              throw ArgumentError(
                'Only one $ResponseHandler annotation is allowed',
              );
            }

            responseHandler = ServerMimic.fromDartObject(object, annotation);
          },
        ),
      ],
    );

    return ServerRouteAnnotations(
      coreMimics: mimics,
      coreTypeReferences: types,
      data: data,
      meta: meta,
      setHeaders: setHeaders,
      allowOrigins: allowOrigins,
      allowHeaders: allowHeaders,
      expectHeaders: expectHeaders,
      responseHandler: responseHandler,
    );
  }

  final _AnnotationTypeReferences coreTypeReferences;
  final _AnnotationMimics coreMimics;
  final Iterable<ServerMimic> data;
  final Iterable<ServerMimic> meta;
  final Iterable<ServerSetHeader> setHeaders;
  final ServerAllowOrigins? allowOrigins;
  final ServerAllowHeaders? allowHeaders;
  final ServerExpectHeaders? expectHeaders;
  ServerMimic? _responseHandler;
  ServerMimic? get responseHandler => _responseHandler;

  void removeResponseHandler() {
    _responseHandler = null;
  }

  bool get hasAnnotations {
    if (coreMimics.all.isNotEmpty) return true;
    if (coreTypeReferences.all.isNotEmpty) return true;
    if (data.isNotEmpty) return true;
    if (meta.isNotEmpty) return true;
    if (setHeaders.isNotEmpty) return true;
    if (allowOrigins != null) return true;
    if (allowHeaders != null) return true;
    if (expectHeaders != null) return true;
    if (responseHandler != null) return true;
    return false;
  }

  @override
  List<ExtractImport?> get extractors => [
        ...coreMimics.all,
        ...coreTypeReferences.all,
        ...data,
        ...meta,
        responseHandler,
      ];

  @override
  List<ServerImports?> get imports => const [];
}

abstract class BaseAnnotations<T> {
  Iterable<T> get middlewares;
  Iterable<T> get interceptors;
  Iterable<T> get catchers;
  Iterable<T> get guards;
  Iterable<T> get combines;
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

  @override
  List<ServerTypeReference> combines = [];

  Iterable<ServerTypeReference> get all => [
        ...catchers,
        ...guards,
        ...interceptors,
        ...middlewares,
        ...combines,
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

  @override
  List<ServerMimic> combines = [];

  Iterable<ServerMimic> get all => [
        ...catchers,
        ...guards,
        ...interceptors,
        ...middlewares,
        ...combines,
      ];
}
