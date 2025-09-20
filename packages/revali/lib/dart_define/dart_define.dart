import 'package:file/file.dart';

class DartDefine {
  const DartDefine({
    Map<String, String> defined = const {},
    List<String> files = const [],
  }) : _files = files,
       _defined = defined;

  factory DartDefine.fromFile(String path, {required FileSystem fs}) {
    final file = fs.file(path);

    if (!file.existsSync()) {
      throw ArgumentError.value(file.path, 'file', 'File does not exist');
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
      defined.addAll(dartDefine._defined);
    }

    for (final entry in entries) {
      final (:key, :value) = _parseEntry(entry);

      defined[key] = value;
    }

    return DartDefine(defined: defined, files: files);
  }

  final Map<String, String> _defined;
  Map<String, String> get defined => Map.unmodifiable(_defined);

  final List<String> _files;
  List<String> get files => List.unmodifiable(_files);

  DartDefine mergeWith(DartDefine define) {
    final merged = <String, String>{};
    final mergedFiles = <String>[];

    merged.addAll(define._defined);
    mergedFiles.addAll(define._files);

    merged.addAll(_defined);
    mergedFiles.addAll(_files);

    return DartDefine(defined: merged, files: mergedFiles);
  }

  List<String> get entries {
    final entries = <String>[];

    for (final MapEntry(:key, :value) in _defined.entries) {
      entries.add('$key=$value');
    }

    return List.unmodifiable(entries);
  }

  @override
  String toString() {
    return 'DartDefine(defined: $_defined, files: $_files)';
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

  bool get isEmpty => _defined.isEmpty;
  bool get isNotEmpty => _defined.isNotEmpty;

  String? operator [](String key) {
    return _defined[key];
  }
}
