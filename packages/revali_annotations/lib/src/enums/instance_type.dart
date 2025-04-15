enum InstanceType {
  /// A singleton instance is created and reused for
  /// the lifetime of the application.
  singleton,

  /// A new instance is created for each request.
  factory;
}
