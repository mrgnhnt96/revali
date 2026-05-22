// ignore_for_file: unnecessary_parenthesis

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:revali_client_gen/enums/parameter_position.dart';
import 'package:revali_client_gen/makers/utils/extract_import.dart';
import 'package:revali_client_gen/makers/utils/type_extensions.dart';
import 'package:revali_client_gen/models/client_imports.dart';
import 'package:revali_client_gen/models/client_lifecycle_component_method.dart';
import 'package:revali_client_gen/models/client_param.dart';
import 'package:revali_client_gen/models/client_type.dart';
import 'package:revali_client_gen/utils/substitute_type.dart';
import 'package:revali_router/revali_router.dart';

class ClientLifecycleComponent with ExtractImport {
  ClientLifecycleComponent({
    required this.guards,
    required this.middlewares,
    required this.interceptors,
    required this.instantiatedTypeArguments,
    required this.genericTypeParameterNames,
  });

  factory ClientLifecycleComponent.fromDartObject(
    DartObject object,
    // ignore: avoid_unused_constructor_parameters
    ElementAnnotation annotation,
  ) {
    if (object.type case final InterfaceType type) {
      final element = type.element;
      if (element is! ClassElement) {
        throw Exception('Invalid element type');
      }

      return ClientLifecycleComponent.fromClassElement(
        element,
        typeArguments: type.typeArguments,
      );
    }

    throw Exception('Expected annotation type to be InterfaceType');
  }

  factory ClientLifecycleComponent.fromClassElement(
    ClassElement element, {
    List<DartType> typeArguments = const [],
  }) {
    final typeSubstitutions = buildTypeSubstitutionMap(element, typeArguments);
    final genericTypeParameterNames = [
      for (final typeParameter in element.typeParameters)
        if (typeParameter.name case final name?) name,
    ];

    Iterable<ClientLifecycleComponentMethod> methodsFromElement() sync* {
      for (final method in element.methods) {
        if (ClientLifecycleComponentMethod.fromElement(
              method,
              typeSubstitutions: typeSubstitutions,
            )
            case final componentMethod?) {
          yield componentMethod;
        }
      }
    }

    final methods = methodsFromElement().toList();

    final guards = <ClientLifecycleComponentMethod>[];
    final middlewares = <ClientLifecycleComponentMethod>[];
    final interceptors = (
      pre: <ClientLifecycleComponentMethod>[],
      post: <ClientLifecycleComponentMethod>[],
    );

    for (final method in methods) {
      final _ = switch (true) {
        _ when method.isGuard => guards.add(method),
        _ when method.isMiddleware => middlewares.add(method),
        _ when method.isInterceptorPre => interceptors.pre.add(method),
        _ when method.isInterceptorPost => interceptors.post.add(method),
        _ => null,
      };
    }

    return ClientLifecycleComponent(
      guards: guards,
      middlewares: middlewares,
      interceptors: interceptors,
      instantiatedTypeArguments: typeSubstitutions.isNotEmpty
          ? typeArguments.map(ClientType.fromType).toList()
          : const <ClientType>[],
      genericTypeParameterNames: genericTypeParameterNames,
    );
  }

  factory ClientLifecycleComponent.fromType(DartType type) {
    final element = type.element;
    if (element is! ClassElement) {
      throw ArgumentError.value(type, 'type', 'Expected a class element');
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

    return ClientLifecycleComponent.fromClassElement(
      element,
      typeArguments: typeArgumentsFrom(type),
    );
  }

  static List<ClientLifecycleComponent> fromTypeReference(
    // ignore: avoid_unused_constructor_parameters
    DartObject object,
    ElementAnnotation annotation,
  ) {
    final typesValue = object.getField('types')?.toListValue();

    if (typesValue == null || typesValue.isEmpty) {
      return [];
    }

    final types = <ClientLifecycleComponent>[];

    for (final typeValue in typesValue) {
      final type = typeValue.toTypeValue();
      if (type == null) {
        throw ArgumentError('Invalid type');
      }

      types.add(ClientLifecycleComponent.fromType(type));
    }

    return types;
  }

  final List<ClientLifecycleComponentMethod> guards;
  final List<ClientLifecycleComponentMethod> middlewares;
  final ({
    List<ClientLifecycleComponentMethod> pre,
    List<ClientLifecycleComponentMethod> post,
  })
  interceptors;
  final List<ClientType> instantiatedTypeArguments;
  final List<String> genericTypeParameterNames;

  bool get shouldSubstituteTypeArguments =>
      instantiatedTypeArguments.isNotEmpty;

  bool shouldExcludeParamFromClient(
    ClientParam param,
    Iterable<ClientParam> endpointParams,
  ) {
    if (param.position != ParameterPosition.body) {
      return false;
    }

    if (shouldSubstituteTypeArguments) {
      return true;
    }

    return endpointParams.any(param.conflictsWithClientParam);
  }

  bool get hasGuards => guards.isNotEmpty;
  bool get hasMiddlewares => middlewares.isNotEmpty;
  bool get hasInterceptors =>
      interceptors.pre.isNotEmpty || interceptors.post.isNotEmpty;

  List<ClientParam> get allParams => [
    ...guards.expand((e) => e.parameters),
    ...middlewares.expand((e) => e.parameters),
    ...interceptors.pre.expand((e) => e.parameters),
    ...interceptors.post.expand((e) => e.parameters),
  ];

  @override
  List<ExtractImport?> get extractors => [
    ...guards,
    ...middlewares,
    ...interceptors.pre,
    ...interceptors.post,
    ...instantiatedTypeArguments,
  ];

  @override
  List<ClientImports?> get imports => [];
}
