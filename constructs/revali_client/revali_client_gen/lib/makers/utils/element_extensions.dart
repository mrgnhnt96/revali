// !!! COPIED FROM revali !!!
// ! path: packages/revali/lib/utils/extensions/element_extensions.dart

import 'package:analyzer/dart/element/element.dart';

extension ElementX on Element {
  String? get importPath {
    return switch (library?.isInSdk) {
      null || true => null,
      false => librarySource?.uri.toString(),
    };
  }
}
