import 'dart:io';

/// Reads configuration from the process environment.
///
/// Environment variables are read at **runtime**, unlike `--dart-define`
/// values, which are compile-time constants baked into the binary. That is the
/// difference that matters in a container: the same image is promoted from
/// staging to production and told what it is by its environment, so anything
/// that differs between deployments — a port, a peer's address, a database
/// URL — has to be read here rather than defined at build time.
///
/// ```dart
/// final users = Env.current.uri('USERS_SERVICE_URL');
/// final key = Env.current.require('API_KEY');
/// ```
///
/// Takes an explicit map in tests, so a suite never has to mutate the real
/// process environment:
///
/// ```dart
/// final env = Env({'PORT': '9000'});
/// ```
class Env {
  Env([Map<String, String>? source]) : _source = source ?? Platform.environment;

  final Map<String, String> _source;

  /// The real process environment.
  static final Env current = Env();

  /// The raw value, or null when unset.
  ///
  /// A variable set to the empty string counts as **unset**. Orchestrators and
  /// CI systems routinely inject empty values for variables that were never
  /// configured, and treating those as a real value is how an app ends up
  /// connecting to `""`.
  String? operator [](String name) {
    final value = _source[name];

    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return value.trim();
  }

  bool has(String name) => this[name] != null;

  /// The value, or [orElse] when unset.
  String string(String name, {required String orElse}) => this[name] ?? orElse;

  /// The value, throwing when unset.
  ///
  /// Use for anything the app genuinely cannot run without. Failing at startup
  /// with the variable's name beats failing on the first request that needed
  /// it, in a stack trace that does not mention configuration at all.
  String require(String name) {
    if (this[name] case final value?) {
      return value;
    }

    throw StateError(
      'Required environment variable "$name" is not set. '
      'Set it in the deployment environment, or supply a default.',
    );
  }

  /// The value parsed as an integer.
  ///
  /// A value that is present but unparseable **throws** rather than falling
  /// back to [orElse]. Someone set it on purpose, and silently ignoring it
  /// would leave the app running on a port nobody routed to.
  int integer(String name, {required int orElse}) {
    final value = this[name];
    if (value == null) {
      return orElse;
    }

    return int.tryParse(value) ??
        (throw StateError(
          'Environment variable "$name" is "$value", which is not an integer.',
        ));
  }

  /// The value parsed as a boolean.
  ///
  /// `true`, `1`, `yes` and `on` are true; `false`, `0`, `no` and `off` are
  /// false, each case-insensitively. Anything else throws rather than being
  /// quietly read as false — a feature flag set to `"maybe"` should be a
  /// deployment error, not a silent no.
  bool boolean(String name, {required bool orElse}) {
    final value = this[name]?.toLowerCase();
    if (value == null) {
      return orElse;
    }

    return switch (value) {
      'true' || '1' || 'yes' || 'on' => true,
      'false' || '0' || 'no' || 'off' => false,
      _ => throw StateError(
          'Environment variable "$name" is "$value", which is not a boolean.',
        ),
    };
  }

  /// The value parsed as a URI — a peer service's base address, typically.
  ///
  /// Throws when present but unparseable, and when [orElse] is omitted and the
  /// variable is unset.
  Uri uri(String name, {Uri? orElse}) {
    final value = this[name];
    if (value == null) {
      if (orElse case final fallback?) {
        return fallback;
      }

      throw StateError(
        'Required environment variable "$name" is not set. '
        'Set it to the base URL of the service.',
      );
    }

    return Uri.tryParse(value) ??
        (throw StateError(
          'Environment variable "$name" is "$value", which is not a URI.',
        ));
  }
}
