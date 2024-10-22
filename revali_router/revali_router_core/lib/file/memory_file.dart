class MemoryFile {
  const MemoryFile(
    this.bytes, {
    required this.mimeType,
    this.basename,
    this.extension,
  });

  factory MemoryFile.from(
    String content, {
    required String mimeType,
    String? basename,
    String? extension,
  }) =>
      MemoryFile(
        content.codeUnits,
        mimeType: mimeType,
        basename: basename,
        extension: extension,
      );

  final List<int> bytes;
  final String mimeType;
  final String? basename;
  final String? extension;

  String get filename {
    final basename = this.basename ?? 'file';
    var extension = '';
    if (this.extension case final ext?) {
      extension = ext;
      if (!extension.startsWith('.')) {
        extension = '.$extension';
      }
    }
    return '$basename$extension';
  }
}
