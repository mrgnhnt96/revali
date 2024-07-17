class AllowOrigins {
  const AllowOrigins(this.origins, {this.inherit = true});
  const AllowOrigins.noInherit(this.origins) : inherit = false;
  const AllowOrigins.all()
      : origins = const {'*'},
        inherit = false;

  /// Whether to inherit the origins from the parent route.
  final bool inherit;
  final Set<String> origins;
}
