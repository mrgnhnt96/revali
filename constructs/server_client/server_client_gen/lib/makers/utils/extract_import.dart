import 'package:server_client_gen/models/client_imports.dart';

mixin ExtractImport {
  List<ClientImports?> get imports;
  List<ExtractImport?> get extractors;

  Iterable<String>? _packageImports;
  Iterable<String>? _pathImports;

  Iterable<String> packageImports() {
    Iterable<String> extract() sync* {
      Iterable<ClientImports> traverse(ExtractImport import) sync* {
        yield* import.imports.whereType<ClientImports>();

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
      Iterable<String> traverse(ExtractImport extract) sync* {
        for (final item in extract.extractors) {
          if (item == null) continue;

          yield* traverse(item);
        }

        for (final import in extract.imports) {
          if (import == null) continue;

          yield* import.paths;
        }
      }

      yield* traverse(this);
    }

    return _pathImports ??= {...extract().toList()..sort()};
  }
}
