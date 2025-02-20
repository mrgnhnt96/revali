class Settings {
  const Settings({
    required this.packageName,
  });

  factory Settings.fromJson(Map<dynamic, dynamic> json) {
    return Settings(
      packageName: json['package_name'] as String? ?? 'client',
    );
  }

  final String packageName;
}
