import 'package:revali_shelf/converters/shelf_imports.dart';

mixin ExtractImport {
  List<ShelfImports?> get imports;
  List<ExtractImport?> get extractors;

  Iterable<String>? _packageImports;
  Iterable<String>? _pathImports;

  Iterable<String> packageImports() {
    Iterable<String> extract() sync* {
      final imports = [
        for (final extractor in extractors) ...?extractor?.imports,
        ...this.imports,
      ];

      for (final import in imports) {
        if (import == null) continue;

        yield* import.packages;
      }
    }

    return _packageImports ??= extract().toSet();
  }

  Iterable<String> pathImports() {
    Iterable<String> extract() sync* {
      final imports = [
        for (final extractor in extractors) ...?extractor?.imports,
        ...this.imports,
      ];

      for (final import in imports) {
        if (import == null) continue;

        yield* import.paths;
      }
    }

    return _pathImports ??= extract().toSet();
  }
}
