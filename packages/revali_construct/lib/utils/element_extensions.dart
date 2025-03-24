import 'package:analyzer/dart/element/element.dart';

extension ElementX on Element {
  String? get importPath {
    return switch (library?.isInSdk) {
      null || true => null,
      false => librarySource?.uri.toString(),
    };
  }

  bool get hasFromJsonConstructor {
    final element = this;

    if (element is! ClassElement) {
      return false;
    }

    return element.constructors.any((ctor) {
      if (ctor.name != 'fromJson') return false;
      if (ctor.parameters.length != 1) return false;

      return true;
    });
  }

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
