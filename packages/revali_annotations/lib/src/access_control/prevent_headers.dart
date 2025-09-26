class PreventHeaders {
  const PreventHeaders(this.headers, {this.inherit = true});
  const PreventHeaders.noInherit(this.headers) : inherit = false;

  /// Whether to inherit the origins from the parent route.
  final bool inherit;
  final Set<String> headers;
}
