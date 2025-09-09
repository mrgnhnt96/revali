import 'package:analyzer/dart/element/element.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_server/converters/base_parameter_annotation.dart';
import 'package:revali_server/converters/server_binds_annotation.dart';
import 'package:revali_server/converters/server_body_annotation.dart';
import 'package:revali_server/converters/server_cookie_annotation.dart';
import 'package:revali_server/converters/server_header_annotation.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_mimic.dart';
import 'package:revali_server/converters/server_param_annotation.dart';
import 'package:revali_server/converters/server_pipe.dart';
import 'package:revali_server/converters/server_query_annotation.dart';
import 'package:revali_server/converters/server_reflect.dart';
import 'package:revali_server/utils/extract_import.dart';

class ServerParamAnnotations with ExtractImport {
  ServerParamAnnotations({
    required this.body,
    required this.query,
    required this.param,
    required this.dep,
    required this.data,
    required this.header,
    required this.cookie,
    required this.binds,
    required this.bind,
  });
  ServerParamAnnotations.none()
      : body = null,
        query = null,
        header = null,
        cookie = null,
        param = null,
        dep = false,
        data = false,
        binds = null,
        bind = null;

  factory ServerParamAnnotations.fromMeta(MetaParam metaParam) {
    return ServerParamAnnotations._getter(metaParam.annotationsFor);
  }

  factory ServerParamAnnotations.fromElement(ParameterElement element) {
    return ServerParamAnnotations._getter(({
      required List<OnMatch> onMatch,
      NonMatch? onNonMatch,
    }) {
      return getAnnotations(
        element: element,
        onMatch: onMatch,
        onNonMatch: onNonMatch,
      );
    });
  }

  factory ServerParamAnnotations._getter(AnnotationMapper getter) {
    ServerBodyAnnotation? body;
    ServerQueryAnnotation? query;
    ServerParamAnnotation? param;
    ServerHeaderAnnotation? header;
    ServerCookieAnnotation? cookie;
    ServerMimic? bind;
    ServerBindsAnnotation? binds;
    bool? dep;
    bool? data;

    getter(
      onMatch: [
        OnMatch(
          classType: Body,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            body = ServerBodyAnnotation.fromElement(object, annotation);
          },
        ),
        OnMatch(
          classType: Query,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            query = ServerQueryAnnotation.fromElement(object, annotation);
          },
        ),
        OnMatch(
          classType: Header,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            header = ServerHeaderAnnotation.fromElement(object, annotation);
          },
        ),
        OnMatch(
          classType: Cookie,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            cookie = ServerCookieAnnotation.fromElement(object, annotation);
          },
        ),
        OnMatch(
          classType: Param,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            param = ServerParamAnnotation.fromElement(object, annotation);
          },
        ),
        OnMatch(
          classType: Bind,
          ignoreGenerics: true,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            bind = ServerMimic.fromDartObject(object, annotation);
          },
        ),
        OnMatch(
          classType: Dep,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            dep = true;
          },
        ),
        OnMatch(
          classType: AddData,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            data = true;
          },
        ),
        OnMatch(
          classType: Binds,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            binds = ServerBindsAnnotation.fromElement(object, annotation);
          },
        ),
      ],
    );

    var isOnlyOne = false;
    for (final annotation in <Object?>[
      body,
      query,
      header,
      param,
      bind,
      dep,
      binds,
      data,
      cookie,
    ]) {
      if (annotation == null) {
        continue;
      }

      if (isOnlyOne) {
        throw ArgumentError(
          'Only one of the following annotations can be used: '
          '@Body, @Query, @Header, @Cookie, @Param, @Dep, @Binds, @Bind',
        );
      }

      isOnlyOne = true;
    }

    return ServerParamAnnotations(
      body: body,
      query: query,
      header: header,
      cookie: cookie,
      param: param,
      bind: bind,
      dep: dep ?? false,
      binds: binds,
      data: data ?? false,
    );
  }

  BaseParameterAnnotation? get baseAnnotation {
    if (body case final value?) {
      return value;
    }

    if (query case final value?) {
      return value;
    }

    if (header case final value?) {
      return value;
    }

    if (cookie case final value?) {
      return value;
    }

    if (param case final value?) {
      return value;
    }

    if (binds case final value?) {
      return value;
    }

    return null;
  }

  final ServerBodyAnnotation? body;
  final ServerQueryAnnotation? query;
  final ServerHeaderAnnotation? header;
  final ServerCookieAnnotation? cookie;
  final ServerParamAnnotation? param;
  final ServerBindsAnnotation? binds;
  final ServerMimic? bind;
  final bool dep;
  final bool data;

  bool get hasAnnotation =>
      body != null ||
      query != null ||
      header != null ||
      cookie != null ||
      param != null ||
      bind != null ||
      binds != null ||
      data ||
      dep;

  Iterable<ServerReflect> get reflects sync* {
    if (body?.pipe?.reflect case final reflect?) {
      yield reflect;
    }

    if (query?.pipe?.reflect case final reflect?) {
      yield reflect;
    }

    if (param?.pipe?.reflect case final reflect?) {
      yield reflect;
    }

    if (header?.pipe?.reflect case final reflect?) {
      yield reflect;
    }

    if (cookie?.pipe?.reflect case final reflect?) {
      yield reflect;
    }

    if (binds?.bind.reflect case final reflect?) {
      yield reflect;
    }
  }

  @override
  List<ExtractImport?> get extractors => [
        body,
        query,
        cookie,
        header,
        param,
        bind,
        bind,
      ];

  @override
  List<ServerImports?> get imports => const [];

  List<ServerPipe> get pipes {
    Iterable<ServerPipe> iterate() sync* {
      if (body?.pipe case final value?) {
        yield value;
      }

      if (query?.pipe case final value?) {
        yield value;
      }

      if (param?.pipe case final value?) {
        yield value;
      }

      if (header?.pipe case final value?) {
        yield value;
      }

      if (cookie?.pipe case final value?) {
        yield value;
      }
    }

    return iterate().toList();
  }
}
