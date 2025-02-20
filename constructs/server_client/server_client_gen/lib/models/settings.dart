class Settings {
  const Settings({
    required this.packageName,
    required this.dependencies,
  });

  factory Settings.fromJson(Map<dynamic, dynamic> json) {
    return Settings(
      packageName: json['package_name'] as String? ?? 'client',
      dependencies: switch (json['dependencies']) {
        final List<dynamic> deps => deps.map((dep) => '${dep ?? ''}').toList(),
        _ => <String>[],
      }
        ..removeWhere((e) => e.isEmpty),
    );
  }

  final String packageName;
  final List<String> dependencies;
}
