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
    () {
      // Keep leading-zero forms as strings (`007`, `05`, `-01`). Numeric
      // parse would drop the zeros, and String query/header bindings that
      // stringify coerced values would then return the wrong wire form.
      if (_hasLeadingZero(value)) {
        throw const FormatException();
      }
      return int.parse(value);
    },
    () {
      if (_hasLeadingZero(value)) {
        throw const FormatException();
      }
      return double.parse(value);
    },
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

bool _hasLeadingZero(String value) {
  // `0` / `-0` are fine as ints; `00`, `007`, `-01` must stay strings.
  return RegExp(r'^-?0\d').hasMatch(value);
}
