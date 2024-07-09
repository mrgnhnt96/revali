import 'package:path/path.dart' as p;

class ShelfImports {
  ShelfImports(Iterable<String> imports) {
    final cleaned = <String>{};

    for (final imprt in imports) {
      if (imprt.startsWith('dart:')) {
        continue;
      }

      if (imprt.startsWith('file:')) {
        final cleanedImport =
            p.relative(imprt.replaceFirst(RegExp('^file:'), ''));

        cleaned.add(cleanedImport);
      } else {
        cleaned.add(imprt);
      }
    }

    this.imports = cleaned;
  }

  late final Iterable<String> imports;
}
