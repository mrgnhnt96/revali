import 'package:path/path.dart' as p;

class AnyFile {
  const AnyFile({
    required this.basename,
    this.content = '',
    this.bytes,
    this.extension,
    this.segments = const [],
  });

  final String basename;
  final List<String> segments;
  final String? extension;
  final String content;

  /// Binary content for this file. When non-null, the generator writes
  /// these bytes directly instead of writing [content] as text.
  final List<int>? bytes;

  List<AnyFile> get subFiles => [];

  String get fileName {
    var prefix = '';
    if (segments case final segments when segments.isNotEmpty) {
      prefix = p.joinAll(segments);
    }

    var file = basename;

    if (extension case final ext? when ext.trim().isNotEmpty) {
      file = p.setExtension(
        file,
        '.${ext.trim().replaceAll(RegExp(r'^\.+'), '')}',
      );
    }

    return p.join(prefix, file);
  }
}
