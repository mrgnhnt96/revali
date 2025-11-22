import 'package:analyzer/dart/element/element2.dart';
import 'package:path/path.dart' as p;
import 'package:revali_construct/revali_construct.dart';

class ServerImports {
  ServerImports(Iterable<String> imports) {
    final paths = <String>{};
    final packages = <String>{};

    for (final import in imports) {
      if (import.startsWith('dart:')) {
        continue;
      }

      if (import.startsWith('file:')) {
        final cleanedImport = p.relative(
          import.replaceFirst(RegExp('^file:'), ''),
        );

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

  factory ServerImports.fromElements(Iterable<Element?> elements) {
    Iterable<String> paths() sync* {
      for (final element in elements) {
        if (element?.importPath case final String path) {
          yield path;
        }
      }
    }

    return ServerImports(paths().toList());
  }

  factory ServerImports.fromElement(Element? element) {
    final path = element?.importPath;

    if (path == null) {
      return ServerImports([]);
    }

    return ServerImports([path]);
  }

  late final Iterable<String> packages;
  late final Iterable<String> paths;
}
