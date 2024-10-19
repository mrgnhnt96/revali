class PayloadResolveException implements Exception {
  const PayloadResolveException({
    required this.encoding,
    required this.contentType,
    required this.content,
    required this.innerException,
  });

  final String encoding;
  final String? contentType;
  final String content;
  final Object innerException;

  @override
  String toString() {
    return 'Failed to resolve payload: $content\n'
        'Encoding: $encoding\n'
        'Content-Type: $contentType\n'
        'Inner exception: $innerException';
  }
}
