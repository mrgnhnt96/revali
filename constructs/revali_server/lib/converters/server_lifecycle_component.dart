// ignore_for_file: unnecessary_parenthesis

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:change_case/change_case.dart';
import 'package:collection/collection.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/converters/server_class.dart';
import 'package:revali_server/converters/server_generic_type.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_lifecycle_component_method.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/converters/server_type.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';
import 'package:revali_server/utils/annotation_argument.dart';
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
    DartObject object,
    ElementAnnotation annotation,
  ) {
    if (object.type case final InterfaceType type) {
      final element = type.element;
      if (element is! ClassElement) {
        throw Exception('Invalid element type');
      }

      final arguments = AnnotationArguments.fromDartObject(annotation);
      final constructor =
          object.constructorInvocation?.constructor ??
          element.constructors.firstWhereOrNull((e) => e.isPublic);

      return ServerLifecycleComponent.fromClassElement(
        element,
        arguments,
        constructor: constructor,
        instanceFields: object,
      );
    }

    throw Exception('Expected annotation type to be InterfaceType');
  }

  factory ServerLifecycleComponent.fromClassElement(
    ClassElement element,
    AnnotationArguments arguments, {
    ConstructorElement? constructor,
    DartObject? instanceFields,
  }) {
    final methods = element.methods
        .map(ServerLifecycleComponentMethod.fromElement)
        .whereType<ServerLifecycleComponentMethod>()
        .toList();

    final guards = <ServerLifecycleComponentMethod>[];
    final middlewares = <ServerLifecycleComponentMethod>[];
    final interceptors = (
      pre: <ServerLifecycleComponentMethod>[],
      post: <ServerLifecycleComponentMethod>[],
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

    final ctor =
        constructor ?? element.constructors.firstWhereOrNull((e) => e.isPublic);

    if (ctor == null) {
      throw ArgumentError.value(
        LifecycleComponent,
        'type',
        'Expected a class element with a public constructor',
      );
    }

    final paramNamesFromConstructor = {
      for (final p in ctor.formalParameters) p.name3 ?? '',
    };

    final params = <ServerParam>[
      ...ctor.formalParameters.map((FormalParameterElement e) {
        final param = ServerParam.fromElement(e);

        if (arguments.all[param.name] case final arg?) {
          param.argument = arg;
        }

        return param;
      }),
      if (instanceFields != null)
        for (final field in element.fields) ...[
          if (_getInitializerListFieldValue(
                field,
                paramNamesFromConstructor,
                instanceFields,
              )
              case final value?)
            ServerParam(
              name: field.name3!,
              type: ServerType.fromType(field.type),
              isRequired: true,
              isNamed: true,
              argument: AnnotationArgument.fromFieldValue(
                field.name3!,
                value,
                field,
              ),
            ),
        ],
    ];

    final name = element.name3;

    if (name == null) {
      throw Exception('Class name is null');
    }

    return ServerLifecycleComponent(
      name: name,
      guards: guards,
      middlewares: middlewares,
      interceptors: interceptors,
      exceptionCatchers: exceptionCatchers,
      params: params,
      import: ServerImports.fromElement(ctor.returnType.element),
      arguments: arguments,
      genericTypes: element.typeParameters
          .map(ServerGenericType.fromElement)
          .toList(),
    );
  }

  factory ServerLifecycleComponent.fromType(DartType type) {
    final element = type.element;
    if (element is! ClassElement) {
      throw ArgumentError.value(type, 'type', 'Expected a class element');
    }

    final superTypeWithoutGenerics = (LifecycleComponent).name;

    if (!element.allSupertypes.any(
      (e) => e.getDisplayString().startsWith(superTypeWithoutGenerics),
    )) {
      throw ArgumentError.value(
        type.getDisplayString(),
        'Annotation',
        'Expected a class that extends $superTypeWithoutGenerics',
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
    List<ServerLifecycleComponentMethod> post,
  })
  interceptors;
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

    final argsByParamName = arguments.all;

    return ServerClass(
      className: className,
      params: [
        ServerParam(
          name: 'di',
          isRequired: true,
          type: ServerType(name: 'DI'),
        ),
        for (final param in params)
          param.copyWith(
            isNamed: true,
            isRequired: !param.type.isNullable,
            argument: argsByParamName[param.name] ?? param.argument,
          ),
      ],
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

  static DartObject? _getInitializerListFieldValue(
    FieldElement field,
    Set<String> paramNamesFromConstructor,
    DartObject instanceFields,
  ) {
    if (field.isStatic) return null;
    final name = field.name3;
    if (name == null || paramNamesFromConstructor.contains(name)) {
      return null;
    }
    return instanceFields.getField(name);
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
  List<ServerImports?> get imports => [import];
}
