class AllowHeaders {
  const AllowHeaders(this.headers, {this.inherit = true});
  const AllowHeaders.noInherit(this.headers) : inherit = false;
  const AllowHeaders.simple()
      : inherit = false,
        headers = const {
          'Accept',
          'Accept-Language',
          'Content-Language',
          'Content-Type',
        };
  const AllowHeaders.common()
      : inherit = false,
        headers = const {
          'Accept-Encoding',
          'Authorization',
          'Cache-Control',
          'Connection',
          'Content-Encoding',
          'Content-Length',
          'Content-Range',
          'Cookie',
          'Date',
          'Host',
          'Origin',
          'User-Agent',
        };

  /// Whether to inherit the origins from the parent route.
  final bool inherit;
  final Set<String> headers;
}
