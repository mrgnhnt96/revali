import 'dart:convert';

dynamic coerce(String value) {
  final attempts = [
    () => int.parse(value),
    () => double.parse(value),
    () => (jsonDecode(value) as List<String>).map(coerce),
    () => (jsonDecode(value) as List).map(
          (e) => e == null ? null : coerce('$e'),
        ),
    () => {
          for (final item in (jsonDecode(value) as Map).entries)
            item.key: item.value == null ? null : coerce('${item.value}'),
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
