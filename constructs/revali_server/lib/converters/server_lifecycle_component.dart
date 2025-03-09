// ignore_for_file: unnecessary_parenthesis

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/element/element.dart';
import 'package:change_case/change_case.dart';
import 'package:collection/collection.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/converters/server_class.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_lifecycle_component_method.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/converters/server_param_annotations.dart';
import 'package:revali_server/converters/server_type.dart';
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
    required this.import,
  });

  factory ServerLifecycleComponent.fromDartObject(
    ElementAnnotation annotation,
  ) {
    final element = annotation.element?.enclosingElement3;

    if (element is! ClassElement) {
      throw Exception('Invalid element type');
    }

    final positionalArguments = <String>[];
    final namedArguments = <String, String>{};

    if (annotation
        case ElementAnnotationImpl(
          annotationAst: Annotation(
            arguments: ArgumentList(childEntities: final args)
          )
        )) {
      for (final param in args) {
        if (param case NamedExpression(:final name, :final expression)) {
          namedArguments[name.label.name] = expression.toSource();
        } else if (param case final Expression expression) {
          positionalArguments.add(expression.toSource());
        }
      }
    }

    if (positionalArguments.isNotEmpty || namedArguments.isNotEmpty) {
      throw Exception(
        'Arguments should not be provided to $LifecycleComponent annotations, '
        'Arguments should be provided using dependency injection. '
        'Class: (${element.name})',
      );
    }

    return ServerLifecycleComponent.fromClassElement(element);
  }

  factory ServerLifecycleComponent.fromClassElement(ClassElement element) {
    final methods = element.methods
        .map(ServerLifecycleComponentMethod.fromElement)
        .whereType<ServerLifecycleComponentMethod>()
        .toList();

    final guards = <ServerLifecycleComponentMethod>[];
    final middlewares = <ServerLifecycleComponentMethod>[];
    final interceptors = (
      pre: <ServerLifecycleComponentMethod>[],
      post: <ServerLifecycleComponentMethod>[]
    );
    final exceptionCatchers = <ServerLifecycleComponentMethod>[];

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

    final constructor =
        element.constructors.firstWhereOrNull((e) => e.isPublic);

    if (constructor == null) {
      throw ArgumentError.value(
        LifecycleComponent,
        'type',
        'Expected a class element with a public constructor',
      );
    }

    final params = constructor.parameters.map(ServerParam.fromElement).toList();
    final importPaths = {
      constructor.returnType.element.librarySource.uri.toString(),
    };

    return ServerLifecycleComponent(
      name: element.name,
      guards: guards,
      middlewares: middlewares,
      interceptors: interceptors,
      exceptionCatchers: exceptionCatchers,
      params: params,
      import: ServerImports(importPaths),
    );
  }

  factory ServerLifecycleComponent.fromType(DartType type) {
    final element = type.element;
    if (element is! ClassElement) {
      throw ArgumentError.value(
        type,
        'type',
        'Expected a class element',
      );
    }

    final superTypeWithoutGenerics = (LifecycleComponent).name;

    if (!element.allSupertypes.any(
      (e) => e.getDisplayString().startsWith(superTypeWithoutGenerics),
    )) {
      throw ArgumentError.value(
        type,
        'type',
        'Expected a class element that extends $superTypeWithoutGenerics',
      );
    }

    return ServerLifecycleComponent.fromClassElement(element);
  }

  static List<ServerLifecycleComponent> fromTypeReference(
    // ignore: avoid_unused_constructor_parameters
    DartObject object,
    ElementAnnotation annotation,
  ) {
    final typesValue = object.getField('types')?.toListValue();

    if (typesValue == null || typesValue.isEmpty) {
      return [];
    }

    final types = <ServerLifecycleComponent>[];

    for (final typeValue in typesValue) {
      final type = typeValue.toTypeValue();
      if (type == null) {
        throw ArgumentError('Invalid type');
      }

      types.add(ServerLifecycleComponent.fromType(type));
    }

    return types;
  }

  final List<ServerLifecycleComponentMethod> guards;
  final List<ServerLifecycleComponentMethod> middlewares;
  final ({
    List<ServerLifecycleComponentMethod> pre,
    List<ServerLifecycleComponentMethod> post
  }) interceptors;
  final List<ServerLifecycleComponentMethod> exceptionCatchers;
  final List<ServerParam> params;
  final String name;
  final ServerImports import;

  bool get hasGuards => guards.isNotEmpty;
  bool get hasMiddlewares => middlewares.isNotEmpty;
  bool get hasInterceptors =>
      interceptors.pre.isNotEmpty || interceptors.post.isNotEmpty;
  bool get hasExceptionCatchers => exceptionCatchers.isNotEmpty;

  ServerClass _create(Type type, {String? subType}) {
    final sub = subType ?? '';
    final className = '$name$sub${(type).name}'.toNoCase().toPascalCase();

    return ServerClass(
      className: className,
      params: [
        ServerParam(
          name: 'di',
          type: ServerType(
            name: 'DI',
            hasFromJsonConstructor: false,
            importPath: null,
          ),
          isNullable: false,
          isNamed: false,
          defaultValue: null,
          hasDefaultValue: false,
          importPath: ServerImports([]),
          annotations: ServerParamAnnotations.none(),
          isRequired: true,
        ),
      ],
      importPath: ServerImports([]),
    );
  }

  ServerClass get exceptionClass {
    return _create(ExceptionCatcher);
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
  List<ServerImports?> get imports => [
        import,
      ];
}
