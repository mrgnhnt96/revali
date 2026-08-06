import 'package:analyzer/dart/element/element.dart';

extension ElementX on Element {
  String? get importPath {
    return switch (library?.isInSdk) {
      null || true => null,
      false => library?.uri.toString(),
    };
  }

  /// Could be a constructor or a static method.
  Element? get fromJsonElement {
    final element = this;

    if (element is ClassElement) {
      return _fromJsonFromClass(element);
    }

    if (element is EnumElement) {
      return _fromJsonFromEnum(element);
    }

    return null;
  }

  /// Arities accepted for a `fromJson` factory/static method.
  ///
  /// `1` is the plain `fromJson(Map json)` shape. When [element] declares
  /// type parameters, `1 + typeParameters.length` is also accepted -- the
  /// `genericArgumentFactories`-style shape where one `T Function(Object?)`
  /// closure follows the json map, one per type parameter, in declaration
  /// order (see `json_serializable`'s `genericArgumentFactories: true`).
  Set<int> _fromJsonArities(ClassElement element) {
    final typeParamCount = element.typeParameters.length;

    return {1, if (typeParamCount > 0) 1 + typeParamCount};
  }

  Element? _fromJsonFromClass(ClassElement element) {
    final arities = _fromJsonArities(element);

    for (final ctor in element.constructors) {
      if (ctor.name != 'fromJson') continue;
      if (!arities.contains(ctor.formalParameters.length)) continue;

      return ctor;
    }

    for (final method in element.methods) {
      if (method.name != 'fromJson') continue;
      if (!method.isStatic) continue;
      if (!arities.contains(method.formalParameters.length)) continue;

      return method;
    }

    return null;
  }

  Element? _fromJsonFromEnum(EnumElement element) {
    for (final method in element.methods) {
      if (method.name != 'fromJson') continue;
      if (!method.isStatic) continue;

      return method;
    }

    return null;
  }

  bool get hasFromJsonConstructor => fromJsonElement != null;

  Element? get toJsonElement {
    final element = this;

    final methods = switch (element) {
      ClassElement(:final methods) => methods,
      EnumElement(:final methods) => methods,
      _ => <MethodElement>[],
    };

    // `0` is the plain `toJson()` shape. When `element` declares type
    // parameters, `typeParameters.length` is also accepted -- the
    // `genericArgumentFactories`-style shape where one `Object Function(T)`
    // closure is required per type parameter, in declaration order.
    final typeParamCount = switch (element) {
      ClassElement(:final typeParameters) => typeParameters.length,
      _ => 0,
    };
    final arities = {0, if (typeParamCount > 0) typeParamCount};

    for (final method in methods) {
      if (method.name != 'toJson') continue;

      final requiredPositionalCount = method.formalParameters
          .where((p) => p.isRequiredPositional)
          .length;
      if (!arities.contains(requiredPositionalCount)) continue;

      return method;
    }

    return null;
  }

  bool get hasToJsonMember => toJsonElement != null;
}
