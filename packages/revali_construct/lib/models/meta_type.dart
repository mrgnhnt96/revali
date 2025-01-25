class MetaType {
  const MetaType({
    required this.name,
    required this.hasFromJsonMethod,
    required this.importPath,
  });

  final String name;
  final bool hasFromJsonMethod;
  final String? importPath;
}
