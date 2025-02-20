// !!! COPIED FROM revali !!!
// ! path: packages/revali/lib/utils/extensions/class_element_extensions.dart

import 'package:analyzer/dart/element/element.dart';

extension ElementX on Element {
  bool get hasFromJsonMember {
    final e = this;
    return switch (e) {
      ClassElement() => e.hasFromJsonMember,
      _ => false,
    };
  }
}

extension ClassElementX on ClassElement {
  bool get hasFromJsonMember {
    return constructors.any((ctor) {
      if (ctor.name != 'fromJson') return false;
      if (ctor.parameters.length != 1) return false;

      return true;
    });
  }
}
