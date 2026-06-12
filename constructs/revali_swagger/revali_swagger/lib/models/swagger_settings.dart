class SwaggerSettings {
  const SwaggerSettings({
    required this.title,
    required this.version,
    this.description,
  });

  factory SwaggerSettings.fromJson(Map<dynamic, dynamic> json) {
    return SwaggerSettings(
      title: json['title'] as String? ?? 'API',
      version: json['version'] as String? ?? '1.0.0',
      description: json['description'] as String?,
    );
  }

  final String title;
  final String version;
  final String? description;
}
