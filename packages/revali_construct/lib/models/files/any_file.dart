import 'package:path/path.dart' as p;

class AnyFile {
  const AnyFile({
    required this.basename,
    required this.content,
    this.extension,
    this.segments = const [],
  });

  final String basename;
  final List<String> segments;
  final String? extension;
  final String content;

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
