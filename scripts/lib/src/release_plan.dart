/// Deciding what a release will actually do, separated from doing it.
///
/// This logic used to live inline in `prep_for_publish.dart` as a single
/// comparison:
///
/// ```dart
/// if (changelog.version != package.version) {
///   yield (package, changelog);
/// }
/// ```
///
/// That is correct for the common case and silent for every other one. Equal
/// versions mean "already published at this version", which is the normal
/// steady state of every package not being released -- so the branch that does
/// nothing is the branch taken by almost every package on almost every run,
/// and it prints nothing at all.
///
/// The consequence is that these two situations are indistinguishable from the
/// script's output:
///
///   * a package is up to date and correctly skipped, and
///   * someone forgot to bump the `LATEST_CHANGELOG.md` heading, so the
///     release they just ran did nothing for that package.
///
/// The second is the one that hides, because a release that publishes nothing
/// still exits 0. A brand-new package is the sharpest version of it: its
/// pubspec and changelog agree at its first version, so it is skipped forever
/// and never reaches the registry. The workaround in the tree today is to
/// start a new package's pubspec at `0.0.0` so the versions differ -- which
/// works, and only works if whoever adds the package remembers.
///
/// Consulting the registry removes the need to remember: "equal" splits into
/// "equal and the registry has it" (genuinely up to date) and "equal and the
/// registry does not" (would be skipped silently, and should not be).
library;

/// What a release run will do with one package, and why.
enum ReleaseAction {
  /// The changelog names a version the pubspec does not. This is the only
  /// action that publishes.
  publish,

  /// Versions agree and the registry confirms that version exists. Skipping
  /// is correct.
  upToDate,

  /// Versions agree but the registry has no such version. Nothing will
  /// publish this package, and nothing would have said so.
  neverPublished,

  /// The registry could not be consulted, so `upToDate` and `neverPublished`
  /// cannot be told apart. Not an error, but not a clean bill of health
  /// either -- reported rather than assumed away.
  unknown,
}

/// What the release script should do at the confirmation gate.
enum ConfirmOutcome {
  /// No package would publish. Nothing to confirm.
  nothingToPublish,

  /// `--yes` was given. Proceed without asking.
  assumedYes,

  /// There is no terminal to prompt on, so the release must decline on
  /// purpose rather than attempt a prompt it cannot complete.
  refuseNoTerminal,

  /// Ask the human.
  ask,
}

/// Decides the confirmation gate without touching `dart:io`.
///
/// This is a function rather than an inline `if` chain because getting it
/// wrong is silent: an earlier version checked only `stdin.hasTerminal`, which
/// under a redirected stdout reads `true` while `stdout.hasTerminal` reads
/// `false`. `mason_logger`'s `confirm` asserts on *stdout*, so the guard let
/// the prompt run and the script died in an unhandled exception instead of
/// declining. It stopped short of publishing by crashing, which is not the
/// same as refusing, and nothing in the test suite could see the difference.
///
/// Both streams are required. A prompt needs somewhere to print the question
/// and somewhere to read the answer, and they are not the same file
/// descriptor.
ConfirmOutcome decideConfirmation({
  required int publishCount,
  required bool assumeYes,
  required bool hasStdinTerminal,
  required bool hasStdoutTerminal,
}) {
  if (publishCount == 0) return ConfirmOutcome.nothingToPublish;
  if (assumeYes) return ConfirmOutcome.assumedYes;
  if (!hasStdinTerminal || !hasStdoutTerminal) {
    return ConfirmOutcome.refuseNoTerminal;
  }

  return ConfirmOutcome.ask;
}

/// One package's disposition in a release.
class PackagePlan {
  const PackagePlan({
    required this.name,
    required this.pubspecVersion,
    required this.changelogVersion,
    required this.action,
    required this.reason,
  });

  final String name;
  final String pubspecVersion;
  final String changelogVersion;
  final ReleaseAction action;

  /// Human-readable justification, shown in the release plan.
  final String reason;

  /// Whether this package needs a human to look at it before publishing.
  ///
  /// [ReleaseAction.unknown] deliberately does not qualify: a registry that
  /// cannot be reached is a property of the network, not of the release, and
  /// promoting it to a blocker would make an offline machine unable to
  /// publish at all.
  bool get isSuspicious => action == ReleaseAction.neverPublished;
}

/// The versions a package declares in the two files that disagree.
class PackageVersions {
  const PackageVersions({
    required this.name,
    required this.pubspecVersion,
    required this.changelogVersion,
  });

  final String name;
  final String pubspecVersion;
  final String changelogVersion;
}

/// Works out what a release will do, without doing any of it.
///
/// [registryVersions] maps a package name to the set of versions the registry
/// reports for it. A `null` value means the lookup failed and the answer is
/// genuinely unknown; an empty set means the lookup succeeded and the package
/// is not published at all. The distinction matters -- collapsing them would
/// report an offline machine as "this package was never published".
List<PackagePlan> planRelease({
  required List<PackageVersions> packages,
  required Map<String, Set<String>?> registryVersions,
}) {
  final plans = <PackagePlan>[];

  for (final package in packages) {
    plans.add(_planFor(package, registryVersions));
  }

  plans.sort((a, b) => a.name.compareTo(b.name));

  return plans;
}

PackagePlan _planFor(
  PackageVersions package,
  Map<String, Set<String>?> registryVersions,
) {
  PackagePlan build(ReleaseAction action, String reason) {
    return PackagePlan(
      name: package.name,
      pubspecVersion: package.pubspecVersion,
      changelogVersion: package.changelogVersion,
      action: action,
      reason: reason,
    );
  }

  if (package.changelogVersion != package.pubspecVersion) {
    return build(
      ReleaseAction.publish,
      'changelog ${package.changelogVersion} != '
      'pubspec ${package.pubspecVersion}',
    );
  }

  // From here the versions agree, which is the case the old code discarded
  // without a word.
  if (!registryVersions.containsKey(package.name)) {
    return build(
      ReleaseAction.unknown,
      'versions agree; registry was not consulted',
    );
  }

  final published = registryVersions[package.name];

  if (published == null) {
    return build(
      ReleaseAction.unknown,
      'versions agree; registry lookup failed',
    );
  }

  if (published.contains(package.changelogVersion)) {
    return build(
      ReleaseAction.upToDate,
      'published at ${package.changelogVersion}',
    );
  }

  return build(
    ReleaseAction.neverPublished,
    published.isEmpty
        ? 'not on the registry at all, and the versions agree, so nothing '
            'will publish it'
        : 'registry has ${published.length} version(s) but not '
            '${package.changelogVersion}, and the versions agree, so nothing '
            'will publish it',
  );
}
