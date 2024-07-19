import 'package:revali_server/converters/server_imports.dart';

mixin ExtractImport {
  List<ServerImports?> get imports;
  List<ExtractImport?> get extractors;

  Iterable<String>? _packageImports;
  Iterable<String>? _pathImports;

  Iterable<String> packageImports() {
    Iterable<String> extract() sync* {
      Iterable<ServerImports> traverse(ExtractImport import) sync* {
        yield* import.imports.whereType<ServerImports>();

        for (final extractor in import.extractors) {
          if (extractor == null) continue;

          yield* traverse(extractor);
        }
      }

      final imports = traverse(this);

      for (final import in imports) {
        yield* import.packages;
      }
    }

    return _packageImports ??= {...extract().toList()..sort()};
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

    return _pathImports ??= {...extract().toList()..sort()};
  }
}
