import 'package:path/path.dart' as p;

class ShelfImports {
  ShelfImports(Iterable<String> imports) {
    final paths = <String>{};
    final packages = <String>{};

    for (final import in imports) {
      if (import.startsWith('dart:')) {
        continue;
      }

      if (import.startsWith('file:')) {
        final cleanedImport =
            p.relative(import.replaceFirst(RegExp('^file:'), ''));

        paths.add(cleanedImport);
        continue;
      }

      if (import.startsWith('package:')) {
        packages.add(import);
        continue;
      }

      throw ArgumentError('Invalid import: $import');
    }

    this.paths = paths;
    this.packages = packages;
  }

  late final Iterable<String> packages;
  late final Iterable<String> paths;
}
