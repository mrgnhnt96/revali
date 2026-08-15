import 'package:args/args.dart';
import 'package:revali/clis/shared/commands/construct_flags.dart';
import 'package:test/test.dart';

/// Rebuilds what the outer CLI forwards to the inner construct runner.
List<String> forward(List<ConstructFlag> flags, ArgResults results) {
  final out = <String>[];

  for (final flag in flags) {
    flag.forward(results, out);
  }

  return out;
}

/// A parser carrying the shared flags plus the outer-only ones, mirroring
/// how `revali dev` declares them.
ArgParser outerDevParser() {
  final parser = ArgParser();
  sharedDevFlags.declareAll(parser);

  return parser
    ..addFlag('recompile', negatable: false)
    ..addFlag('skip-if-fresh', negatable: false)
    ..addFlag('inspect', negatable: false)
    ..addOption('cert')
    ..addOption('key');
}

void main() {
  group('shared construct flags', () {
    test('the inner parser accepts everything the forwarder emits', () {
      // The guarantee that makes the whole design work: whatever comes out of
      // forward() must parse against a parser built from the same list.
      final inner = ArgParser();
      sharedDevFlags.declareAll(inner);

      final results = outerDevParser().parse([
        '--flavor',
        'prod',
        '--release',
        '--dart-define',
        'A=1',
        '--recompile',
        '--cert',
        'a.pem',
        '--key',
        'b.pem',
      ]);

      expect(
        () => inner.parse(forward(sharedDevFlags, results)),
        returnsNormally,
      );
    });

    group('outer-only flags are never forwarded', () {
      test('when passed in space form', () {
        final results = outerDevParser().parse([
          '--recompile',
          '--skip-if-fresh',
          '--inspect',
          '--cert',
          'a.pem',
          '--key',
          'b.pem',
        ]);

        expect(forward(sharedDevFlags, results), isEmpty);
      });

      test('when passed in equals form', () {
        // Regression: the old forwarder filtered raw argument strings, so the
        // single token `--cert=a.pem` never matched the `--cert` it looked
        // for and leaked into the inner parser, which has no `cert` option.
        final results = outerDevParser().parse(['--cert=a.pem', '--key=b.pem']);

        expect(forward(sharedDevFlags, results), isEmpty);
      });
    });

    test('equals-form shared flags are normalised to separate tokens', () {
      final results = outerDevParser().parse(['--flavor=prod']);

      expect(forward(sharedDevFlags, results), ['--flavor', 'prod']);
    });

    test('a shared flag is forwarded exactly once', () {
      // The old forwarder prepended `--flavor <value>` *and* let the raw
      // `--flavor=prod` token through, emitting it twice.
      final results = outerDevParser().parse(['--flavor=prod', '--release']);
      final forwarded = forward(sharedDevFlags, results);

      expect(forwarded.where((e) => e == '--flavor'), hasLength(1));
    });

    test('unpassed flags are not forwarded, defaults included', () {
      final results = outerDevParser().parse([]);

      // `dart-vm-service-port` defaults to '0' but was not passed, so it must
      // not be emitted -- the inner parser applies the same default itself.
      expect(forward(sharedDevFlags, results), isEmpty);
    });

    test('multi-options forward every value as its own token pair', () {
      final results = outerDevParser().parse([
        '--dart-define',
        'A=1',
        '--dart-define',
        'B=2',
      ]);

      expect(forward(sharedDevFlags, results), [
        '--dart-define',
        'A=1',
        '--dart-define',
        'B=2',
      ]);
    });

    test('an explicitly empty option value is dropped', () {
      final results = outerDevParser().parse(['--flavor', '']);

      expect(forward(sharedDevFlags, results), isEmpty);
    });

    test('build forwards its shared flags and not --recompile', () {
      final parser = ArgParser();
      sharedBuildFlags.declareAll(parser);
      parser.addFlag('recompile', negatable: false);

      final results = parser.parse([
        '--recompile',
        '--flavor=staging',
        '--profile',
      ]);

      expect(forward(sharedBuildFlags, results), [
        '--flavor',
        'staging',
        '--profile',
      ]);
    });

    test('--type has no default, so an unpassed build selects no phase', () {
      // It used to default to `build`, which skips every construct, so a plain
      // `revali build` never regenerated the client. Null is what tells the
      // command to run both phases.
      final parser = ArgParser();
      sharedBuildFlags.declareAll(parser);

      expect(parser.parse([])['type'], isNull);
    });

    test('--type takes a single phase, and rejects the removed one', () {
      // `revali_docker` writes `--type constructs` into the Dockerfiles it
      // generates, and `_compileServer` shells out with it. Both live outside
      // this repo's control once emitted, so the value has to keep parsing.
      final parser = ArgParser();
      sharedBuildFlags.declareAll(parser);

      expect(parser.parse(['--type=constructs'])['type'], 'constructs');
      expect(parser.parse(['--type=build'])['type'], 'build');
      expect(
        () => parser.parse(['--type=buildAndConstructs']),
        throwsA(isA<FormatException>()),
      );
    });

    test('a false boolean flag is not forwarded', () {
      final results = outerDevParser().parse([]);

      expect(forward(sharedDevFlags, results), isNot(contains('--release')));
    });
  });
}
