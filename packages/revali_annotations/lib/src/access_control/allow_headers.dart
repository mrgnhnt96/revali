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
          'Range',
        };

  /// Whether to inherit the origins from the parent route.
  final bool inherit;
  final Set<String> headers;
}
