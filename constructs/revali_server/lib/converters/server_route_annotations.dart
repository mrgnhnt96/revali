// ignore_for_file: library_private_types_in_public_api

import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/converters/annotation_mimics.dart';
import 'package:revali_server/converters/annotation_type_references.dart';
import 'package:revali_server/converters/server_allow_headers.dart';
import 'package:revali_server/converters/server_allow_origins.dart';
import 'package:revali_server/converters/server_expect_headers.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_lifecycle_component.dart';
import 'package:revali_server/converters/server_mimic.dart';
import 'package:revali_server/converters/server_set_header.dart';
import 'package:revali_server/converters/server_type_reference.dart';
import 'package:revali_server/utils/extract_import.dart';

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
    required this.lifecycleComponents,
  }) : _responseHandler = responseHandler;

  ServerRouteAnnotations.none()
      : this(
          coreMimics: AnnotationMimics(),
          coreTypeReferences: AnnotationTypeReferences(),
          data: [],
          meta: [],
          setHeaders: [],
          allowOrigins: null,
          allowHeaders: null,
          expectHeaders: null,
          responseHandler: null,
          lifecycleComponents: [],
        );

  factory ServerRouteAnnotations.fromApp(MetaAppConfig app) {
    return ServerRouteAnnotations._fromGetter(app.annotationsFor);
  }
  factory ServerRouteAnnotations.fromParent(MetaRoute parent) {
    return ServerRouteAnnotations._fromGetter(parent.annotationsFor);
  }

  factory ServerRouteAnnotations.fromRoute(MetaMethod method) {
    return ServerRouteAnnotations._fromGetter(method.annotationsFor);
  }

  factory ServerRouteAnnotations._fromGetter(AnnotationMapper getter) {
    final mimics = AnnotationMimics();
    final types = AnnotationTypeReferences();

    final data = <ServerMimic>[];
    final setHeaders = <ServerSetHeader>[];
    final meta = <ServerMimic>[];
    ServerAllowOrigins? allowOrigins;
    ServerAllowHeaders? allowHeaders;
    ServerExpectHeaders? expectHeaders;
    ServerMimic? responseHandler;
    final lifecycleComponents = <ServerLifecycleComponent>[];

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
          classType: LifecycleComponent,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            lifecycleComponents.add(
              ServerLifecycleComponent.fromDartObject(annotation),
            );
          },
        ),
        OnMatch(
          classType: LifecycleComponents,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            if (ServerLifecycleComponent.fromTypeReference(object, annotation)
                case final components) {
              lifecycleComponents.addAll(components);
            }
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
            if (allowOrigins case final origins?) {
              allowOrigins =
                  origins.merge(ServerAllowOrigins.fromDartObject(object));
            } else {
              allowOrigins = ServerAllowOrigins.fromDartObject(object);
            }
          },
        ),
        OnMatch(
          classType: AllowHeaders,
          package: 'revali_annotations',
          convert: (object, annotation) {
            if (allowHeaders case final headers?) {
              allowHeaders =
                  headers.merge(ServerAllowHeaders.fromDartObject(object));
            } else {
              allowHeaders = ServerAllowHeaders.fromDartObject(object);
            }
          },
        ),
        OnMatch(
          classType: ExpectHeaders,
          package: 'revali_annotations',
          convert: (object, annotation) {
            if (expectHeaders case final headers?) {
              expectHeaders =
                  headers.merge(ServerExpectHeaders.fromDartObject(object));
            } else {
              expectHeaders = ServerExpectHeaders.fromDartObject(object);
            }
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
      lifecycleComponents: lifecycleComponents,
    );
  }

  final AnnotationTypeReferences coreTypeReferences;
  final AnnotationMimics coreMimics;
  final List<ServerMimic> data;
  final List<ServerMimic> meta;
  final List<ServerSetHeader> setHeaders;
  final ServerAllowOrigins? allowOrigins;
  final ServerAllowHeaders? allowHeaders;
  final ServerExpectHeaders? expectHeaders;
  final List<ServerLifecycleComponent> lifecycleComponents;
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
    if (lifecycleComponents.isNotEmpty) return true;
    return false;
  }

  @override
  List<ExtractImport?> get extractors => [
        ...coreMimics.all,
        ...coreTypeReferences.all,
        ...data,
        ...meta,
        responseHandler,
        ...lifecycleComponents,
      ];

  @override
  List<ServerImports?> get imports => const [];
}
