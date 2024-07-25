class Options {
  const Options({
    required this.ignoreLints,
  });

  // ignore: strict_raw_type
  factory Options.fromJson(Map? json) {
    final ignoreLints = json?['ignore_lints'];

    return Options(
      ignoreLints: switch (ignoreLints) {
        List<String>() => ignoreLints,
        List() => ignoreLints.map((e) => '$e').toList(),
        String() => [ignoreLints],
        _ => [],
      },
    );
  }

  final List<String> ignoreLints;
}
