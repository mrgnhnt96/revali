import 'dart:convert';

/// Coerces a value already produced by [jsonDecode] (or nested inside one).
dynamic coerceDynamic(dynamic value) {
  if (value == null) return null;

  return switch (value) {
    final Map<dynamic, dynamic> map => {
        for (final entry in map.entries) entry.key: coerceDynamic(entry.value),
      },
    final List<dynamic> list => [
        for (final element in list) coerceDynamic(element),
      ],
    final String string => coerce(string),
    _ => value,
  };
}

dynamic coerce(String value) {
  final attempts = [
    () => int.parse(value),
    () => double.parse(value),
    () {
      final decoded = jsonDecode(value);
      return decoded is Map || decoded is List
          ? coerceDynamic(decoded)
          : decoded;
    },
    () => switch (value) {
          'true' => true,
          'false' => false,
          _ => throw const FormatException(),
        },
  ];

  for (final attempt in attempts) {
    try {
      final result = attempt();

      return result;
    } catch (_) {}
  }

  return value;
}
