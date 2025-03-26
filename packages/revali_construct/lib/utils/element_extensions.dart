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

    if (element is! ClassElement) {
      return null;
    }

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

  bool get hasFromJsonConstructor => fromJsonElement != null;

  bool get hasToJsonMember {
    final element = this;

    if (element is! ClassElement) {
      return false;
    }

    return element.methods.any((method) {
      if (method.name != 'toJson') return false;

      return true;
    });
  }
}
