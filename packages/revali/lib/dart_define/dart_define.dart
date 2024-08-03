import 'package:file/file.dart';

class DartDefine {
  const DartDefine({
    this.defined = const {},
    this.files = const [],
  });

  factory DartDefine.fromFile(String path, {required FileSystem fs}) {
    final file = fs.file(path);

    if (!file.existsSync()) {
      throw ArgumentError.value(
        file.path,
        'file',
        'File does not exist',
      );
    }

    final lines = file.readAsLinesSync();

    final defined = <String, String>{};

    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      if (line.startsWith('#')) continue;

      final (:key, :value) = _parseEntry(line);

      defined[key] = value;
    }

    return DartDefine(defined: defined, files: [file.path]);
  }

  factory DartDefine.fromFilesAndEntries({
    required List<String> files,
    required List<String> entries,
    required FileSystem fs,
  }) {
    final defined = <String, String>{};

    for (final file in files) {
      final dartDefine = DartDefine.fromFile(file, fs: fs);
      defined.addAll(dartDefine.defined);
    }

    for (final entry in entries) {
      final (:key, :value) = _parseEntry(entry);

      defined[key] = value;
    }

    return DartDefine(defined: defined, files: files);
  }

  final Map<String, String> defined;
  final List<String> files;

  DartDefine mergeWith(DartDefine define) {
    final merged = <String, String>{};
    final mergedFiles = <String>[];

    merged.addAll(define.defined);
    mergedFiles.addAll(define.files);

    merged.addAll(defined);
    mergedFiles.addAll(files);

    return DartDefine(defined: merged, files: mergedFiles);
  }

  List<String> get entries {
    final entries = <String>[];

    for (final MapEntry(:key, :value) in defined.entries) {
      entries.add('$key=$value');
    }

    return entries;
  }

  @override
  String toString() {
    return 'DartDefine(defined: $defined, files: $files)';
  }

  static String _sanitized(String value) {
    var sanitized = value;

    sanitized = sanitized.trim();

    sanitized = sanitized.replaceAll(RegExp(r'^"|"$'), '');

    return sanitized;
  }

  static ({String key, String value}) _parseEntry(String entry) {
    final parts = entry.split('=');

    if (parts.length != 2) {
      throw ArgumentError.value(
        entry,
        'entry',
        'Expected entry to be in the format of KEY=VALUE',
      );
    }

    return (key: _sanitized(parts[0]), value: _sanitized(parts[1]));
  }

  bool get isEmpty => defined.isEmpty;
  bool get isNotEmpty => defined.isNotEmpty;

  String? operator [](String key) {
    return defined[key];
  }
}
