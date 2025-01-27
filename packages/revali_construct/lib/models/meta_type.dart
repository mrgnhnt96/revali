class MetaType {
  const MetaType({
    required this.name,
    required this.hasFromJsonConstructor,
    required this.importPath,
  });

  final String name;
  final bool hasFromJsonConstructor;
  final String? importPath;
}
