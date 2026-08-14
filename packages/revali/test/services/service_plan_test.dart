import 'package:file/memory.dart';
import 'package:revali/services/service_discovery.dart';
import 'package:revali/services/service_plan.dart';
import 'package:test/test.dart';

void main() {
  late MemoryFileSystem fs;

  setUp(() => fs = MemoryFileSystem());

  RevaliService service(String path, String name) {
    fs.directory('/repo/$path').createSync(recursive: true);

    return RevaliService(
      name: name,
      directory: fs.directory('/repo/$path'),
      relativePath: path,
    );
  }

  group('planServices', () {
    test('gives each service its own port, in order', () {
      final plans = planServices([
        service('a', 'a'),
        service('b', 'b'),
        service('c', 'c'),
      ]);

      expect(plans.map((p) => p.port), [8080, 8081, 8082]);
    });

    test('honours a custom base port', () {
      final plans = planServices([
        service('a', 'a'),
        service('b', 'b'),
      ], basePort: 4000);

      expect(plans.map((p) => p.port), [4000, 4001]);
    });

    test('labels by package name when unique', () {
      final plans = planServices([service('svc/users', 'users')]);

      expect(plans.single.label, 'users');
    });

    test('labels by path when names collide', () {
      final plans = planServices([
        service('examples/one', 'hello'),
        service('examples/two', 'hello'),
        service('users', 'users'),
      ]);

      // Two identical prefixes in a merged stream is worse than a long one:
      // there is then no way to tell which process a line came from.
      expect(plans.map((p) => p.label), [
        'examples/one',
        'examples/two',
        'users',
      ]);
    });

    group('--only', () {
      test('selects by package name', () {
        final plans = planServices(
          [service('a', 'alpha'), service('b', 'beta')],
          only: ['beta'],
        );

        expect(plans.single.label, 'beta');
      });

      test('selects by path', () {
        final plans = planServices(
          [service('a', 'alpha'), service('b', 'beta')],
          only: ['a'],
        );

        expect(plans.single.label, 'alpha');
      });

      test('renumbers ports from the base', () {
        final plans = planServices(
          [service('a', 'alpha'), service('b', 'beta'), service('c', 'gamma')],
          only: ['beta', 'gamma'],
        );

        // The selection is the fleet; leaving gaps would waste ports and
        // make the printed list confusing.
        expect(plans.map((p) => p.port), [8080, 8081]);
      });

      test('ignores blank entries', () {
        final plans = planServices(
          [service('a', 'alpha')],
          only: ['alpha', '  ', ''],
        );

        expect(plans, hasLength(1));
      });

      test('throws on a name that does not exist', () {
        // Silently running a subset is worse than refusing: a typo would
        // otherwise look like a service that starts and does nothing.
        expect(
          () => planServices([service('a', 'alpha')], only: ['alhpa']),
          throwsA(isA<UnknownServiceException>()),
        );
      });

      test('names what it could not find, and what is available', () {
        final error = () {
          try {
            planServices([service('a', 'alpha')], only: ['nope']);
          } on UnknownServiceException catch (e) {
            return '$e';
          }

          return '';
        }();

        expect(error, contains('nope'));
        expect(error, contains('alpha'));
      });
    });
  });

  group('prefixLines', () {
    test('prefixes each line', () {
      expect(prefixLines('one\ntwo', 'svc'), ['svc | one', 'svc | two']);
    });

    test('drops blank lines', () {
      // Child processes emit plenty; prefixing them just adds noise.
      expect(prefixLines('one\n\n  \ntwo', 'svc'), ['svc | one', 'svc | two']);
    });

    test('keeps only the final frame of a line that redrew itself', () {
      // A bare \r means "replace what I just drew". Passing it through would
      // return the cursor to column 0 and overwrite the prefix saying which
      // service the line came from; treating it as a line break is the other
      // extreme, and turns one spinner into a wall of frames.
      expect(prefixLines('one\r\u2713 done', 'svc'), ['svc | \u2713 done']);
    });

    test('drops a spinner frame that has not resolved yet', () {
      // Frames arrive one write at a time, so the first lands in its own
      // chunk. Printing it leaves a stray line above every result, and with
      // several services interleaved that is most of the output.
      expect(prefixLines('\u280b Generating server code...', 'svc'), isEmpty);
    });

    test('keeps a line that does not animate', () {
      expect(prefixLines('Serving at http://0.0.0.0:8080/api', 'svc'), [
        'svc | Serving at http://0.0.0.0:8080/api',
      ]);
    });

    test('collapses a whole spinner animation to its result', () {
      // What `revali up` actually receives while a child generates code.
      const spinner =
          '\u280b Retrieving constructs...'
          '\r\u2819 Retrieving constructs...'
          '\r\u2839 Retrieving constructs...'
          '\r\u2713 Retrieved constructs (61ms)';

      expect(prefixLines(spinner, 'orders'), [
        'orders | \u2713 Retrieved constructs (61ms)',
      ]);
    });

    test('collapses \r\n rather than emitting a blank line', () {
      expect(prefixLines('one\r\ntwo', 'svc'), ['svc | one', 'svc | two']);
    });

    test('returns nothing for an empty chunk', () {
      expect(prefixLines('', 'svc'), isEmpty);
    });
  });

  group('colorFor', () {
    test('is stable for an index', () {
      expect(colorFor(2), colorFor(2));
    });

    test('differs between neighbours', () {
      expect(colorFor(0), isNot(colorFor(1)));
    });

    test('wraps around rather than running out', () {
      expect(colorFor(99), isNotNull);
    });
  });
}
