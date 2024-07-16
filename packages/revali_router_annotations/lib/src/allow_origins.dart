class AllowOrigins {
  const AllowOrigins([this.origins = const {}]);
  const AllowOrigins.all() : origins = const {'*'};

  final Set<String> origins;
}
