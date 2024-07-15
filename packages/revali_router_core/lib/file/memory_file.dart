class MemoryFile {
  const MemoryFile(
    this.bytes, {
    required this.mimeType,
    this.basename,
    this.extension,
  });

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
