class Settings {
  const Settings({
    required this.packageName,
    required this.integrations,
    required this.scheme,
  });

  factory Settings.fromJson(Map<dynamic, dynamic> json) {
    return Settings(
      packageName: json['package_name'] as String? ?? 'client',
      integrations: switch (json['integrations']) {
        final Map<String, bool> map => map,
        final Map<String, bool?> map =>
          map.map((key, value) => MapEntry(key, value ?? true)),
        final Map<String, dynamic> map => map.map(
            (key, value) => MapEntry(
              key,
              switch (value) {
                'true' => true,
                'false' => false,
                true => true,
                false => false,
                _ => true,
              },
            ),
          ),
        _ => const {},
      },
      scheme: json['scheme'] as String? ?? 'http',
    );
  }

  final String packageName;
  final String scheme;
  final Map<String, bool> integrations;

  bool get integrateGetIt => integrations['get_it'] ?? false;
}
