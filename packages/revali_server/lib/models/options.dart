class Options {
  const Options({
    required this.ignoreLints,
  });

  factory Options.fromJson(Map? json) {
    final ignoreLints = json?['ignore_lints'];

    return Options(
        ignoreLints: switch (ignoreLints) {
      List<String>() => ignoreLints,
      List() => ignoreLints.map((e) => '$e').toList(),
      String() => [ignoreLints],
      _ => [],
    });
  }

  final List<String> ignoreLints;
}
