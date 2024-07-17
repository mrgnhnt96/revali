class AllowHeaders {
  const AllowHeaders(this.headers, {this.inherit = true});
  const AllowHeaders.noInherit(this.headers) : inherit = false;

  /// Whether to inherit the origins from the parent route.
  final bool inherit;
  final Set<String> headers;
}
