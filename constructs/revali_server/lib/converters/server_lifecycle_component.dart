// ignore_for_file: unnecessary_parenthesis

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:change_case/change_case.dart';
import 'package:collection/collection.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/converters/server_class.dart';
import 'package:revali_server/converters/server_generic_type.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_lifecycle_component_method.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/converters/server_param_annotations.dart';
import 'package:revali_server/converters/server_type.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';
import 'package:revali_server/utils/annotation_arguments.dart';
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
    required this.arguments,
    required this.genericTypes,
  });

  factory ServerLifecycleComponent.fromDartObject(
    ElementAnnotation annotation,
  ) {
    final element = annotation.element?.enclosingElement3;

    if (element is! ClassElement) {
      throw Exception('Invalid element type');
    }

    final arguments = AnnotationArguments.fromDartObject(annotation);

    return ServerLifecycleComponent.fromClassElement(element, arguments);
  }

  factory ServerLifecycleComponent.fromClassElement(
    ClassElement element,
    AnnotationArguments arguments,
  ) {
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

    final params = constructor.parameters.map((e) {
      final param = ServerParam.fromElement(e);

      if (arguments.all[param.name] case final arg?) {
        param.argument = arg;
      }

      return param;
    }).toList();

    return ServerLifecycleComponent(
      name: element.name,
      guards: guards,
      middlewares: middlewares,
      interceptors: interceptors,
      exceptionCatchers: exceptionCatchers,
      params: params,
      import: ServerImports.fromElement(constructor.returnType.element),
      arguments: arguments,
      genericTypes:
          element.typeParameters.map(ServerGenericType.fromElement).toList(),
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

    return ServerLifecycleComponent.fromClassElement(
      element,
      AnnotationArguments.none(),
    );
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
  final AnnotationArguments arguments;
  final List<ServerGenericType> genericTypes;

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
          isNamed: false,
          defaultValue: null,
          hasDefaultValue: false,
          importPath: ServerImports([]),
          annotations: ServerParamAnnotations.none(),
          isRequired: true,
          type: ServerType(
            name: 'DI',
            fromJson: null,
            importPath: null,
            isVoid: false,
            reflect: null,
            isFuture: false,
            isStream: false,
            iterableType: null,
            isNullable: false,
            isPrimitive: false,
            isStringContent: false,
            hasToJsonMember: false,
            isMap: false,
            typeArguments: [],
            recordProps: null,
            isRecord: false,
          ),
        ),
        for (final arg in arguments.positional)
          ServerParam(
            name: arg.parameterName,
            type: arg.type,
            isNamed: true,
            defaultValue: null,
            hasDefaultValue: false,
            importPath: ServerImports([]),
            annotations: ServerParamAnnotations.none(),
            isRequired: !arg.type.isNullable,
            argument: arg,
          ),
        for (final MapEntry(:key, value: arg) in arguments.named.entries)
          ServerParam(
            name: key,
            type: arg.type,
            isNamed: true,
            defaultValue: null,
            hasDefaultValue: false,
            importPath: ServerImports([]),
            annotations: ServerParamAnnotations.none(),
            isRequired: arg.isRequired,
            argument: arg,
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
        arguments,
      ];

  @override
  List<ServerImports?> get imports => [
        import,
      ];
}
