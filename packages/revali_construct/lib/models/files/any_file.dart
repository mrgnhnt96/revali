class AnyFile {
  const AnyFile({
    required this.basename,
    required this.content,
    this.extension,
  });

  final String basename;
  final String? extension;
  final String content;

  String get fileName {
    if (extension case final ext? when ext.trim().isNotEmpty) {
      return '$basename.${ext.trim().replaceAll(RegExp(r'^\.+'), '')}';
    }

    return basename;
  }
}
