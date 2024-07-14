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
}
