/// Controls gzip compression of responses.
///
/// Compression is negotiated: a response is only ever compressed for a client
/// that asked for it with `Accept-Encoding: gzip`, so enabling this cannot
/// break a client that did not.
class CompressionSettings {
  const CompressionSettings({
    this.enabled = true,
    this.minBytes = 1024,
    this.mimeTypes = defaultMimeTypes,
  });

  const CompressionSettings.disabled()
      : enabled = false,
        minBytes = 0,
        mimeTypes = const {};

  /// Whether to compress at all.
  final bool enabled;

  /// Responses smaller than this are sent uncompressed.
  ///
  /// Below roughly a packet's worth there is nothing to save — gzip's own
  /// header can leave a tiny body *larger* than it started.
  final int minBytes;

  /// Mime types worth compressing.
  ///
  /// Only text-shaped payloads are listed. Images, video, and archives are
  /// already compressed, so running them through gzip burns CPU to make them
  /// marginally bigger.
  final Set<String> mimeTypes;

  static const defaultMimeTypes = {
    'text/plain',
    'text/html',
    'text/css',
    'text/csv',
    'text/markdown',
    'text/xml',
    'application/json',
    'application/ld+json',
    'application/xml',
    'application/javascript',
    'application/manifest+json',
    'image/svg+xml',
  };

  bool allows(String? mimeType) {
    if (!enabled || mimeType == null) {
      return false;
    }

    return mimeTypes.contains(mimeType.toLowerCase());
  }
}
