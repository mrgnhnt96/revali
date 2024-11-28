// ignore_for_file: unnecessary_parenthesis

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:change_case/change_case.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/converters/server_class.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/converters/server_param_annotations.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';
import 'package:revali_server/utils/extract_import.dart';

class ServerLifecycleComponent with ExtractImport {
  ServerLifecycleComponent({
    required this.name,
    required this.guards,
    required this.middlewares,
    required this.interceptors,
    required this.exceptionCatchers,
    required this.params,
  });

  factory ServerLifecycleComponent.fromDartObject(
    // ignore: avoid_unused_constructor_parameters
    DartObject object,
    ElementAnnotation annotation,
  ) {
    final element = annotation.element?.enclosingElement;

    if (element is! ClassElement) {
      throw Exception('Invalid element type');
    }
    final methods = element.methods
        .map(ComponentMethod.fromElement)
        .whereType<ComponentMethod>()
        .toList();

    final guards = <ComponentMethod>[];
    final middlewares = <ComponentMethod>[];
    final interceptors = (pre: <ComponentMethod>[], post: <ComponentMethod>[]);
    final exceptionCatchers = <ComponentMethod>[];

    for (final method in methods) {
      final _ = switch (true) {
        _ when method.isGuard => guards.add(method),
        _ when method.isMiddleware => middlewares.add(method),
        _ when method.isInterceptorPre => interceptors.pre.add(method),
        _ when method.isInterceptorPost => interceptors.post.add(method),
        _ when method.isExceptionCatcher => exceptionCatchers.add(method),
        _ => null,
      };
    }

    final params = element.constructors.first.parameters
        .map(ServerParam.fromElement)
        .toList();

    return ServerLifecycleComponent(
      name: element.name,
      guards: guards,
      middlewares: middlewares,
      interceptors: interceptors,
      exceptionCatchers: exceptionCatchers,
      params: params,
    );
  }

  final List<ComponentMethod> guards;
  final List<ComponentMethod> middlewares;
  final ({List<ComponentMethod> pre, List<ComponentMethod> post}) interceptors;
  final List<ComponentMethod> exceptionCatchers;
  final List<ServerParam> params;
  final String name;

  bool get hasGuards => guards.isNotEmpty;
  bool get hasMiddlewares => middlewares.isNotEmpty;
  bool get hasInterceptors =>
      interceptors.pre.isNotEmpty || interceptors.post.isNotEmpty;
  bool get hasExceptionCatchers => exceptionCatchers.isNotEmpty;

  ServerClass _create(Type type, {String? subType}) {
    final sub = subType ?? '';
    final className = '$name$sub${(type).name}'.toNoCase().toPascalCase();
    return ServerClass(
      className: '_$className',
      params: [
        ServerParam(
          name: 'di',
          type: 'DI',
          isNullable: false,
          isNamed: false,
          defaultValue: null,
          hasDefaultValue: false,
          importPath: ServerImports([]),
          annotations: ServerParamAnnotations.none(),
          typeImport: null,
          isRequired: true,
        ),
      ],
      importPath: ServerImports([]),
    );
  }

  List<(ServerClass, ComponentMethod)> get exceptionClasses {
    return [
      for (final method in exceptionCatchers)
        (exceptionClassFor(method), method),
    ];
  }

  ServerClass exceptionClassFor(ComponentMethod method) {
    return _create(ExceptionCatcher, subType: method.exceptionType);
  }

  ServerClass get guardClass {
    return _create(Guard);
  }

  ServerClass get middlewareClass {
    return _create(Middleware);
  }

  ServerClass get interceptorClass {
    return _create(Interceptor);
  }

  @override
  List<ExtractImport?> get extractors => [
        ...guards,
        ...middlewares,
        ...interceptors.pre,
        ...interceptors.post,
        ...exceptionCatchers,
        ...params,
      ];

  @override
  List<ServerImports?> get imports => [];
}

class ComponentMethod with ExtractImport {
  ComponentMethod({
    required this.name,
    required this.isFuture,
    required this.returnType,
    required this.parameters,
    required this.exceptionType,
  });

  static ComponentMethod? fromElement(MethodElement object) {
    final name = object.name;

    final returnTypeAlias = object.returnType.alias?.element.name;
    String returnType;
    var isFuture = false;
    String? exceptionType;

    if (returnTypeAlias != null && aliasReturnTypes.contains(returnTypeAlias)) {
      returnType = returnTypeAlias;
    } else if (object.returnType case final InterfaceType type
        when type.isAnyFuture) {
      isFuture = true;
      final typeArg = type.typeArguments.first;
      returnType = typeArg.getDisplayString();

      if (returnType.startsWith((ExceptionCatcherResult).name)) {
        throw ArgumentError('Exception types cannot be a Future type');
      }
    } else {
      returnType = object.returnType.getDisplayString();

      if (object.returnType case final InterfaceType type
          when returnType.startsWith((ExceptionCatcherResult).name)) {
        returnType = (ExceptionCatcherResult).name;
        exceptionType = type.typeArguments.first.getDisplayString();
      }
    }

    if (!returnTypes.contains(returnType)) {
      return null;
    }

    final params = object.parameters.map(ServerParam.fromElement).toList();

    return ComponentMethod(
      name: name,
      isFuture: isFuture,
      returnType: returnType,
      parameters: params,
      exceptionType: exceptionType,
    );
  }

  final String name;
  final String returnType;
  final bool isFuture;
  final List<ServerParam> parameters;

  /// The type of the exception that this method catches,
  /// If this method is not an exception catcher, this will be null
  final String? exceptionType;

  static const interceptorPre = 'InterceptorPreResult';
  static const interceptorPost = 'InterceptorPostResult';

  static final aliasReturnTypes = {
    interceptorPre,
    interceptorPost,
  };

  static final returnTypes = {
    ...coreReturnTypes,
    ...aliasReturnTypes,
  };

  static final coreReturnTypes = {
    (GuardResult).name,
    (MiddlewareResult).name,
    (ExceptionCatcherResult).name,
  };

  bool get isGuard => returnType == (GuardResult).name;
  bool get isMiddleware => returnType == (MiddlewareResult).name;
  bool get isInterceptorPre => returnType == interceptorPre;
  bool get isInterceptorPost => returnType == interceptorPost;
  bool get isExceptionCatcher => returnType == (ExceptionCatcherResult).name;

  @override
  List<ExtractImport?> get extractors => [
        ...parameters,
      ];

  @override
  List<ServerImports?> get imports => [];
}

extension _DartTypeX on DartType {
  bool get isAnyFuture => isDartAsyncFuture || isDartAsyncFutureOr;
}
