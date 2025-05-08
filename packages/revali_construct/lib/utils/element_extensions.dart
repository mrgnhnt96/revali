import 'package:analyzer/dart/element/element.dart';

extension ElementX on Element {
  String? get importPath {
    return switch (library?.isInSdk) {
      null || true => null,
      false => librarySource?.uri.toString(),
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

  Element? _fromJsonFromClass(ClassElement element) {
    for (final ctor in element.constructors) {
      if (ctor.name != 'fromJson') continue;
      if (ctor.parameters.length != 1) continue;

      return ctor;
    }

    for (final method in element.methods) {
      if (method.name != 'fromJson') continue;
      if (!method.isStatic) continue;

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

    for (final method in methods) {
      if (method.name != 'toJson') continue;

      return method;
    }

    return null;
  }

  bool get hasToJsonMember => toJsonElement != null;
}
