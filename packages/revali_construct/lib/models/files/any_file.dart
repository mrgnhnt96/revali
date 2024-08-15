class AnyFile {
  const AnyFile({
    required this.basename,
    required this.extension,
    required this.content,
  });

  final String basename;
  final String extension;
  final String content;

  String get fileName {
    if (extension.isEmpty) {
      return basename;
    }

    return '$basename.$extension';
  }
}
