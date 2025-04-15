class Settings {
  const Settings({
    required this.packageName,
    required this.integrations,
    required this.serverName,
    required this.scheme,
  });

  factory Settings.fromJson(Map<dynamic, dynamic> json) {
    final serverName = switch (json['server_name']) {
      final String name when name.trim().isNotEmpty => name.trim(),
      _ => 'Server',
    };

    if (serverName.contains(RegExp(r'\s'))) {
      throw ArgumentError('server_name cannot contain spaces');
    }

    return Settings(
      packageName: json['package_name'] as String? ?? 'client',
      serverName: serverName,
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
  final String serverName;
  final String scheme;
  final Map<String, bool> integrations;

  bool get integrateGetIt => integrations['get_it'] ?? false;
}
