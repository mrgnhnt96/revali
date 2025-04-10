class Args {
  const Args({
    Map<String, dynamic>? args,
    List<String>? rest,
  })  : _args = args ?? const {},
        _rest = rest ?? const [];

  factory Args.parse(List<String> args) {
    // --no-<key> should be false under <key>
    // --<key> should be true under <key>
    // --key=value should be value under key
    final mapped = <String, dynamic>{};
    final rest = <String>[];

    void add(String rawKey, dynamic value) {
      final key = switch (rawKey.split('--')) {
        [final key] => key,
        [_, final key] => key,
        _ => throw ArgumentError('Invalid key: $rawKey'),
      };

      if (mapped[key] case null) {
        mapped[key] = value;
        return;
      }

      // add to existing list of values
      // ignore: strict_raw_type
      if (mapped[key] case final Iterable list) {
        mapped[key] = list.followedBy([value]);
        return;
      }

      // starts a new list
      mapped[key] = [mapped[key], value];
    }

    for (var i = 0; i < args.length; i++) {
      final arg = args[i];

      if (!arg.startsWith('--')) {
        rest.add(arg);
        continue;
      }

      if (arg.split('=') case [final key, final value]) {
        add(key, value);
        continue;
      }

      if (arg.split('--no-') case [_, final key]) {
        mapped[key] = false;
        continue;
      }

      final key = arg.substring(2);

      if (i + 1 < args.length) {
        if (args[i + 1] case final String value when !value.startsWith('--')) {
          add(key, value);
          i++;
          continue;
        }
      }

      mapped[key] = true;
    }

    return Args(args: mapped, rest: rest);
  }

  final Map<String, dynamic> _args;
  final List<String> _rest;
  List<String> get rest => List.unmodifiable(_rest);
  List<String> get keys => _args.keys.toList();

  Map<String, bool> get flags {
    final flags = <String, bool>{};

    for (final entry in _args.entries) {
      if (entry.value case final bool value) {
        flags[entry.key] = value;
      }
    }

    return Map.unmodifiable(flags);
  }

  Map<String, dynamic> get values => Map.unmodifiable(_args);

  bool wasParsed(String key) => _args[key] != null;

  T get<T>(String key) {
    if (!wasParsed(key)) {
      throw ArgumentError('Key $key was not parsed');
    }

    if (_args[key] case final T value) {
      return value;
    }

    throw ArgumentError('Key $key was not parsed as $T');
  }
}
