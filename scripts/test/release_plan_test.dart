import 'package:scripts/src/release_plan.dart';
import 'package:test/test.dart';

PackageVersions pkg(
  String name, {
  required String pubspec,
  required String changelog,
}) {
  return PackageVersions(
    name: name,
    pubspecVersion: pubspec,
    changelogVersion: changelog,
  );
}

PackagePlan planOne(
  PackageVersions package, {
  Map<String, Set<String>?> registry = const {},
}) {
  return planRelease(packages: [package], registryVersions: registry).single;
}

void main() {
  group('planRelease', () {
    test('publishes when the changelog names a version the pubspec does not',
        () {
      final plan = planOne(
        pkg('revali', pubspec: '3.2.0', changelog: '3.3.0'),
        registry: {
          'revali': {'3.2.0'},
        },
      );

      expect(plan.action, ReleaseAction.publish);
      expect(plan.isSuspicious, isFalse);
    });

    test('a differing version publishes even when the registry is unreachable',
        () {
      // The registry is an extra signal, never a precondition -- an offline
      // machine must still be able to cut a release.
      final plan = planOne(
        pkg('revali', pubspec: '3.2.0', changelog: '3.3.0'),
        registry: {'revali': null},
      );

      expect(plan.action, ReleaseAction.publish);
    });

    test('equal versions are up to date when the registry has that version',
        () {
      // The real state of revali_test and revali_mcp: equal at 0.1.0 in both
      // files *and* live on pub.dev at 0.1.0. Skipping them is correct, and
      // bumping them would republish something already released.
      final plan = planOne(
        pkg('revali_test', pubspec: '0.1.0', changelog: '0.1.0'),
        registry: {
          'revali_test': {'0.1.0'},
        },
      );

      expect(plan.action, ReleaseAction.upToDate);
      expect(plan.isSuspicious, isFalse);
      expect(plan.reason, contains('published at 0.1.0'));
    });

    test(
        'equal versions on a package absent from the registry are flagged, '
        'not skipped', () {
      // This is the case the old `changelog != pubspec` check could not see.
      // A brand-new package whose first version appears in both files is
      // skipped forever and never reaches the registry -- silently, and with
      // the release still exiting 0.
      final plan = planOne(
        pkg('revali_redis', pubspec: '0.1.0', changelog: '0.1.0'),
        registry: {'revali_redis': <String>{}},
      );

      expect(plan.action, ReleaseAction.neverPublished);
      expect(plan.isSuspicious, isTrue);
      expect(plan.reason, contains('nothing will publish it'));
    });

    test('equal versions naming a version the registry lacks are flagged', () {
      // Published before, but not at *this* version -- e.g. a failed publish
      // that left the pubspec bumped. Equally invisible under the old check.
      final plan = planOne(
        pkg('revali_client', pubspec: '3.0.0', changelog: '3.0.0'),
        registry: {
          'revali_client': {'2.0.0', '2.1.0'},
        },
      );

      expect(plan.action, ReleaseAction.neverPublished);
      expect(plan.isSuspicious, isTrue);
      expect(plan.reason, contains('but not 3.0.0'));
    });

    test('a failed registry lookup is unknown, never "never published"', () {
      // Collapsing these would report every package as unpublished the moment
      // the network drops, which trains you to ignore the warning.
      final plan = planOne(
        pkg('revali_test', pubspec: '0.1.0', changelog: '0.1.0'),
        registry: {'revali_test': null},
      );

      expect(plan.action, ReleaseAction.unknown);
      expect(plan.isSuspicious, isFalse);
      expect(plan.reason, contains('lookup failed'));
    });

    test('a package missing from the registry map is unknown, not a failure',
        () {
      final plan = planOne(
        pkg('revali_test', pubspec: '0.1.0', changelog: '0.1.0'),
      );

      expect(plan.action, ReleaseAction.unknown);
      expect(plan.reason, contains('not consulted'));
    });

    test('every package gets a plan, sorted by name', () {
      final plans = planRelease(
        packages: [
          pkg('revali_router', pubspec: '5.0.0', changelog: '5.1.0'),
          pkg('revali', pubspec: '3.2.0', changelog: '3.3.0'),
          pkg('revali_core', pubspec: '3.0.0', changelog: '3.0.0'),
        ],
        registryVersions: {
          'revali': {'3.2.0'},
          'revali_router': {'5.0.0'},
          'revali_core': {'3.0.0'},
        },
      );

      // Every package is accounted for. The old code yielded only the ones it
      // was going to publish, so a package's absence from the output carried
      // no information at all.
      expect(
        plans.map((p) => p.name),
        ['revali', 'revali_core', 'revali_router'],
      );
      expect(
        plans.map((p) => p.action),
        [ReleaseAction.publish, ReleaseAction.upToDate, ReleaseAction.publish],
      );
    });

    test('a package whose plan says "current" still appears in the output', () {
      // Regression guard for a bug found only by running the real script: the
      // non-publishing entries were routed through logger.detail, which
      // mason_logger hides unless verbose. The plan listed 8 of 13 packages
      // and revali_test/revali_mcp were invisible again -- the exact defect
      // the plan exists to fix, reintroduced inside the fix.
      //
      // planRelease returning an entry is what makes printing it possible, so
      // this pins the contract the printer depends on.
      final plans = planRelease(
        packages: [
          pkg('revali', pubspec: '3.2.0', changelog: '3.3.0'),
          pkg('revali_test', pubspec: '0.1.0', changelog: '0.1.0'),
        ],
        registryVersions: {
          'revali': {'3.2.0'},
          'revali_test': {'0.1.0'},
        },
      );

      expect(plans, hasLength(2));
      expect(plans.map((p) => p.name), contains('revali_test'));
    });

    test('the staged release in the tree today produces no suspicious entries',
        () {
      // Guards the specific claim the handoff got wrong: with revali_test and
      // revali_mcp genuinely live at 0.1.0, the staged set is clean and needs
      // no version bumps.
      final plans = planRelease(
        packages: [
          pkg('revali', pubspec: '3.2.0', changelog: '3.3.0'),
          pkg('revali_redis', pubspec: '0.0.0', changelog: '0.1.0'),
          pkg('revali_test', pubspec: '0.1.0', changelog: '0.1.0'),
          pkg('revali_mcp', pubspec: '0.1.0', changelog: '0.1.0'),
        ],
        registryVersions: {
          'revali': {'3.2.0'},
          'revali_redis': <String>{},
          'revali_test': {'0.1.0'},
          'revali_mcp': {'0.1.0'},
        },
      );

      expect(plans.where((p) => p.isSuspicious), isEmpty);
      expect(
        plans
            .where((p) => p.action == ReleaseAction.publish)
            .map((p) => p.name),
        ['revali', 'revali_redis'],
      );
    });
  });

  group('decideConfirmation', () {
    ConfirmOutcome decide({
      int publishCount = 8,
      bool assumeYes = false,
      bool stdinTty = true,
      bool stdoutTty = true,
    }) {
      return decideConfirmation(
        publishCount: publishCount,
        assumeYes: assumeYes,
        hasStdinTerminal: stdinTty,
        hasStdoutTerminal: stdoutTty,
      );
    }

    test('asks when there is a terminal on both streams', () {
      expect(decide(), ConfirmOutcome.ask);
    });

    test('refuses when stdout has no terminal even though stdin does', () {
      // The exact observed situation: the real run reported
      // "stdin: true, stdout: false". A guard checking only stdin returns
      // "ask" here, mason_logger's confirm then asserts on stdout, and the
      // script dies with an unhandled exception rather than declining.
      expect(decide(stdoutTty: false), ConfirmOutcome.refuseNoTerminal);
    });

    test('refuses when stdin has no terminal even though stdout does', () {
      expect(decide(stdinTty: false), ConfirmOutcome.refuseNoTerminal);
    });

    test('refuses when neither stream has a terminal', () {
      expect(
        decide(stdinTty: false, stdoutTty: false),
        ConfirmOutcome.refuseNoTerminal,
      );
    });

    test('--yes proceeds with no terminal on either stream', () {
      // The CI path. It has to be typed, which is the whole difference from
      // the previous behaviour of publishing unconditionally.
      expect(
        decide(assumeYes: true, stdinTty: false, stdoutTty: false),
        ConfirmOutcome.assumedYes,
      );
    });

    test('nothing to publish outranks every other condition', () {
      expect(
        decide(publishCount: 0, stdinTty: false, stdoutTty: false),
        ConfirmOutcome.nothingToPublish,
      );
    });
  });
}
