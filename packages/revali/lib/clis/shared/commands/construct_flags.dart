import 'package:args/args.dart';
import 'package:revali_construct/revali_construct.dart';

/// A command-line flag understood by **both** the outer `revali` CLI and the
/// inner construct runner that executes inside the generated entrypoint.
///
/// Each shared flag is declared exactly once — here — and both parsers are
/// built from the same list. The two commands used to declare their flags
/// independently, and the outer command forwarded them by filtering the raw
/// argument strings. That had two problems this design removes structurally:
///
/// - `--flag=value` is a single token, so it never matched the `--flag` the
///   filter looked for. `revali dev --cert=a.pem` leaked `--cert=a.pem` into
///   the inner parser, which does not declare `cert`, and failed to parse.
/// - Every new flag was a three-place edit: declare inner, declare outer, and
///   update the outer-only strip list. Missing the third leaked the flag.
///
/// [forward] emits from *parsed* results rather than raw strings, so a flag
/// absent from the shared list cannot reach the inner runner at all.
sealed class ConstructFlag {
  const ConstructFlag({
    required this.name,
    required this.help,
    this.hide = false,
  });

  final String name;
  final String help;
  final bool hide;

  /// Adds this flag to [parser]. Called for both the outer and inner command.
  void declare(ArgParser parser);

  /// Appends this flag to [out] if it was explicitly passed.
  ///
  /// Values are emitted as separate `--name value` tokens so a value that
  /// itself contains `=` (`--dart-define BASE_URL=https://…`) stays
  /// unambiguous.
  void forward(ArgResults results, List<String> out);
}

final class ConstructBoolFlag extends ConstructFlag {
  const ConstructBoolFlag({
    required super.name,
    required super.help,
    super.hide,
  });

  @override
  void declare(ArgParser parser) =>
      parser.addFlag(name, help: help, hide: hide, negatable: false);

  @override
  void forward(ArgResults results, List<String> out) {
    if (results.wasParsed(name) && (results[name] as bool? ?? false)) {
      out.add('--$name');
    }
  }
}

final class ConstructOption extends ConstructFlag {
  const ConstructOption({
    required super.name,
    required super.help,
    super.hide,
    this.abbr,
    this.valueHelp,
    this.defaultsTo,
    this.allowed,
    this.allowedHelp,
  });

  final String? abbr;
  final String? valueHelp;
  final String? defaultsTo;
  final Iterable<String>? allowed;
  final Map<String, String>? allowedHelp;

  @override
  void declare(ArgParser parser) => parser.addOption(
    name,
    abbr: abbr,
    help: help,
    hide: hide,
    valueHelp: valueHelp,
    defaultsTo: defaultsTo,
    allowed: allowed,
    allowedHelp: allowedHelp,
  );

  @override
  void forward(ArgResults results, List<String> out) {
    if (!results.wasParsed(name)) {
      return;
    }

    // An explicitly empty value is dropped rather than forwarded as `""`,
    // matching how the previous forwarder guarded `--flavor`.
    if (results[name] case final String value when value.isNotEmpty) {
      out
        ..add('--$name')
        ..add(value);
    }
  }
}

final class ConstructMultiOption extends ConstructFlag {
  const ConstructMultiOption({
    required super.name,
    required super.help,
    super.hide,
    this.abbr,
    this.valueHelp,
  });

  final String? abbr;
  final String? valueHelp;

  @override
  void declare(ArgParser parser) => parser.addMultiOption(
    name,
    abbr: abbr,
    help: help,
    hide: hide,
    valueHelp: valueHelp,
  );

  @override
  void forward(ArgResults results, List<String> out) {
    if (!results.wasParsed(name)) {
      return;
    }

    for (final value in results[name] as List<String>) {
      out
        ..add('--$name')
        ..add(value);
    }
  }
}

extension ConstructFlagList on List<ConstructFlag> {
  /// Declares every flag in this list on [parser].
  void declareAll(ArgParser parser) {
    for (final flag in this) {
      flag.declare(parser);
    }
  }
}

const _flavor = ConstructOption(
  name: 'flavor',
  abbr: 'f',
  help: 'The flavor to use for the app (case-sensitive)',
);

const _profile = ConstructBoolFlag(
  name: 'profile',
  help:
      'Whether to run in profile mode. Enables logger, '
      'but disables hot reload and debugger',
);

const _dartDefine = ConstructMultiOption(
  name: 'dart-define',
  abbr: 'D',
  help: 'Additional key-value pairs that will be available as constants.',
  valueHelp: 'BASE_URL=https://api.example.com',
);

const _dartDefineFromFile = ConstructMultiOption(
  name: 'dart-define-from-file',
  help:
      'A file containing additional key-value '
      'pairs that will be available as constants.',
  valueHelp: '.env',
);

/// Flags shared by the outer `revali dev` and the construct runner's `dev`.
///
/// Outer-only flags (`recompile`, `skip-if-fresh`, `inspect`, `cert`, `key`)
/// are deliberately absent — the outer command declares those itself and they
/// are never forwarded.
const sharedDevFlags = <ConstructFlag>[
  _flavor,
  ConstructBoolFlag(
    name: 'release',
    help:
        'Whether to run in release mode. '
        'Disables hot reload, debugger, and logger',
  ),
  _profile,
  ConstructBoolFlag(
    name: 'debug',
    help:
        '(Default) Whether to run in debug mode. '
        'Enables hot reload, debugger, and logger',
  ),
  ConstructBoolFlag(
    name: 'generate-only',
    help: 'Only generate the constructs, does not run the server',
    hide: true,
  ),
  ConstructOption(
    name: 'dart-vm-service-port',
    help:
        'The port to use for the Dart VM service. '
        'Use 0 to automatically assign a port.',
    defaultsTo: '0',
  ),
  _dartDefine,
  _dartDefineFromFile,
];

/// Flags shared by the outer `revali build` and the construct runner's
/// `build`. `recompile` is outer-only and is never forwarded.
final sharedBuildFlags = <ConstructFlag>[
  _flavor,
  const ConstructBoolFlag(
    name: 'release',
    help:
        '(Default) Whether to run in release mode. '
        'Disables hot reload, debugger, and logger',
  ),
  _profile,
  ConstructOption(
    name: 'type',
    help: 'Which constructs to generate',
    hide: true,
    defaultsTo: GenerateConstructType.build.name,
    allowed: GenerateConstructType.values.map((e) => e.name),
    allowedHelp: {
      for (final type in GenerateConstructType.values)
        type.name: type.description,
    },
  ),
  _dartDefine,
  _dartDefineFromFile,
];
