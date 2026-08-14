import 'package:revali_core/revali_core.dart';
import 'package:test/test.dart';

/// A concrete config, since [AppConfig] is abstract.
final class _App extends AppConfig {
  _App({super.env, super.defaultPort, super.defaultHost}) : super.fromEnv();
}

void main() {
  group('Env', () {
    test('reads a value', () {
      expect(Env({'A': 'one'})['A'], 'one');
    });

    test('trims surrounding whitespace', () {
      expect(Env({'A': '  one  '})['A'], 'one');
    });

    test('treats an empty value as unset', () {
      // Orchestrators and CI routinely inject empty values for variables that
      // were never configured; reading those as real is how an app connects
      // to "".
      expect(Env({'A': ''})['A'], isNull);
      expect(Env({'A': '   '})['A'], isNull);
      expect(Env({'A': ''}).has('A'), isFalse);
    });

    test('falls back when unset', () {
      expect(Env({}).string('A', orElse: 'fallback'), 'fallback');
    });

    group('require', () {
      test('returns the value', () {
        expect(Env({'A': 'one'}).require('A'), 'one');
      });

      test('throws naming the variable', () {
        // Failing at startup with the name beats failing on the first request
        // that needed it, in a trace that never mentions configuration.
        expect(
          () => Env({}).require('API_KEY'),
          throwsA(
            isA<StateError>()
                .having((e) => e.message, 'message', contains('API_KEY')),
          ),
        );
      });
    });

    group('integer', () {
      test('parses', () {
        expect(Env({'PORT': '9000'}).integer('PORT', orElse: 8080), 9000);
      });

      test('falls back when unset', () {
        expect(Env({}).integer('PORT', orElse: 8080), 8080);
      });

      test('throws rather than falling back when unparseable', () {
        // Someone set it on purpose. Listening somewhere else instead is
        // worse than not starting.
        expect(
          () => Env({'PORT': 'eighty'}).integer('PORT', orElse: 8080),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('boolean', () {
      test('accepts the usual spellings', () {
        for (final value in ['true', 'TRUE', '1', 'yes', 'on']) {
          expect(
            Env({'F': value}).boolean('F', orElse: false),
            isTrue,
            reason: value,
          );
        }
        for (final value in ['false', 'FALSE', '0', 'no', 'off']) {
          expect(
            Env({'F': value}).boolean('F', orElse: true),
            isFalse,
            reason: value,
          );
        }
      });

      test('throws on anything else', () {
        // A flag set to "maybe" is a deployment error, not a silent no.
        expect(
          () => Env({'F': 'maybe'}).boolean('F', orElse: false),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('uri', () {
      test('parses a peer address', () {
        expect(
          Env({'USERS': 'http://users:8080'}).uri('USERS'),
          Uri.parse('http://users:8080'),
        );
      });

      test('falls back when given one', () {
        expect(
          Env({}).uri('USERS', orElse: Uri.parse('http://localhost:1')),
          Uri.parse('http://localhost:1'),
        );
      });

      test('throws when unset and no fallback', () {
        expect(() => Env({}).uri('USERS'), throwsA(isA<StateError>()));
      });
    });
  });

  group('AppConfig.fromEnv', () {
    test('binds every interface, not just loopback', () {
      // localhost inside a container accepts only connections from that same
      // container, so every request from outside is refused while the process
      // looks perfectly healthy.
      expect(_App(env: Env({})).host, '0.0.0.0');
    });

    test('takes the port the platform assigned', () {
      // Cloud Run, Heroku, Render and Fly all assign a port this way.
      expect(_App(env: Env({'PORT': '9000'})).port, 9000);
    });

    test('falls back to 8080 when PORT is unset', () {
      expect(_App(env: Env({})).port, 8080);
    });

    test('honours HOST when set', () {
      expect(_App(env: Env({'HOST': '127.0.0.1'})).host, '127.0.0.1');
    });

    test('refuses to start on an unparseable PORT', () {
      expect(
        () => _App(env: Env({'PORT': 'eighty'})),
        throwsA(isA<StateError>()),
      );
    });

    test('accepts overridden defaults', () {
      expect(
        _App(env: Env({}), defaultHost: '::1', defaultPort: 1234).host,
        '::1',
      );
      expect(_App(env: Env({}), defaultPort: 1234).port, 1234);
    });

    test('keeps the usual prefix', () {
      expect(_App(env: Env({})).prefix, 'api');
    });
  });
}
