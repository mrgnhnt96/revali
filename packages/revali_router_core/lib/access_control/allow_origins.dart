import 'package:revali_annotations/revali_annotations.dart' as annotations;

class AllowOrigins implements annotations.AllowOrigins {
  const AllowOrigins(this.origins, {this.inherit = true});

  /// Whether to inherit the origins from the parent route.
  @override
  final bool inherit;

  @override
  final Set<String> origins;
}
