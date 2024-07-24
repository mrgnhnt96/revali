import 'dart:convert';

dynamic coerce(dynamic value) {
  final attempts = [
    () => int.parse(value),
    () => double.parse(value),
    () => (jsonDecode(value) as List).map(coerce),
    () => {
          for (final item in (jsonDecode(value) as Map).entries)
            item.key: coerce(item.value),
        },
    () => switch (value) {
          'true' => true,
          'false' => false,
          _ => throw '',
        },
    () => value,
  ];

  for (final attempt in attempts) {
    try {
      final result = attempt();

      return result;
    } catch (_) {}
  }

  throw FormatException('Failed to coerce value: $value');
}
