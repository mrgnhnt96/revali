// !!! COPIED FROM revali !!!
// ! path: packages/revali/lib/utils/extensions/element_extensions.dart

import 'package:analyzer/dart/element/element2.dart';

extension ElementX on Element {
  String? get importPath {
    return switch (library?.isInSdk) {
      null || true => null,
      false => library?.uri.toString(),
    };
  }
}
