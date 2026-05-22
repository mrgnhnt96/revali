import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

Map<String, DartType> buildTypeSubstitutionMap(
  ClassElement element,
  List<DartType> typeArguments,
) {
  final typeParameters = element.typeParameters;

  if (typeParameters.isEmpty ||
      typeArguments.isEmpty ||
      typeParameters.length != typeArguments.length) {
    return const {};
  }

  final substitutions = <String, DartType>{};

  for (var i = 0; i < typeParameters.length; i++) {
    final name = typeParameters[i].name;
    if (name == null) {
      continue;
    }

    final typeArgument = typeArguments[i];
    if (typeArgument is DynamicType) {
      continue;
    }

    substitutions[name] = typeArgument;
  }

  if (substitutions.length != typeParameters.length) {
    return const {};
  }

  return substitutions;
}

List<DartType> typeArgumentsFrom(DartType type) {
  return switch (type) {
    InterfaceType(:final typeArguments) => typeArguments,
    _ => const [],
  };
}

DartType substituteType(DartType type, Map<String, DartType> substitutions) {
  if (substitutions.isEmpty) {
    return type;
  }

  switch (type) {
    case TypeParameterType(:final element):
      final name = element.name;
      if (name == null || !substitutions.containsKey(name)) {
        return type;
      }

      return _withNullability(substitutions[name]!, type.nullabilitySuffix);

    case InterfaceType(:final element, :final typeArguments):
      if (typeArguments.isEmpty) {
        return type;
      }

      final substitutedArguments = typeArguments
          .map((argument) => substituteType(argument, substitutions))
          .toList(growable: false);

      if (_typesEqual(substitutedArguments, typeArguments)) {
        return type;
      }

      return element.instantiate(
        typeArguments: substitutedArguments,
        nullabilitySuffix: type.nullabilitySuffix,
      );

    default:
      return type;
  }
}

DartType _withNullability(DartType type, NullabilitySuffix nullabilitySuffix) {
  if (type.nullabilitySuffix == nullabilitySuffix) {
    return type;
  }

  return switch (type) {
    InterfaceType(:final element, :final typeArguments) => element.instantiate(
      typeArguments: typeArguments,
      nullabilitySuffix: nullabilitySuffix,
    ),
    _ => type,
  };
}

bool _typesEqual(List<DartType> a, List<DartType> b) {
  if (a.length != b.length) {
    return false;
  }

  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }

  return true;
}
