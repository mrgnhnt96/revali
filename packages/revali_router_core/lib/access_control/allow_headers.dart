import 'package:revali_annotations/revali_annotations.dart' as annotations;

class AllowHeaders implements annotations.AllowHeaders {
  const AllowHeaders(this.headers, {this.inherit = true});

  /// Whether to inherit the origins from the parent route.
  @override
  final bool inherit;

  @override
  final Set<String> headers;
}
