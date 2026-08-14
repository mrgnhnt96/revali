import 'package:file/memory.dart';
import 'package:revali/services/compose_maker.dart';
import 'package:revali/services/service_discovery.dart';
import 'package:test/test.dart';

void main() {
  late MemoryFileSystem fs;

  setUp(() => fs = MemoryFileSystem());

  void makeService(
    String path,
    String name, {
    bool routes = true,
    bool dependsOnRevali = true,
    bool dockerfile = false,
  }) {
    final dir = fs.directory(path)..createSync(recursive: true);

    dir.childFile('pubspec.yaml').writeAsStringSync('''
name: $name
${dependsOnRevali ? 'dependencies:\n  revali_router:' : ''}
''');

    if (routes) {
      dir.childDirectory('routes').createSync();
    }

    if (dockerfile) {
      final build = dir.childDirectory('.revali').childDirectory('build')
        ..createSync(recursive: true);
      build.childFile('Dockerfile').writeAsStringSync('FROM dart:stable');
    }
  }

  group('ServiceDiscovery', () {
    test('finds nothing in an empty repo', () {
      fs.directory('/repo').createSync(recursive: true);

      expect(const ServiceDiscovery().find(fs.directory('/repo')), isEmpty);
    });

    test('finds a service by its pubspec and routes directory', () {
      makeService('/repo/users', 'users_service');

      final found = const ServiceDiscovery().find(fs.directory('/repo'));

      expect(found, hasLength(1));
      expect(found.single.name, 'users_service');
      expect(found.single.relativePath, 'users');
    });

    test('finds several, ordered by path', () {
      makeService('/repo/services/orders', 'orders');
      makeService('/repo/services/billing', 'billing');
      makeService('/repo/services/users', 'users');

      final found = const ServiceDiscovery().find(fs.directory('/repo'));

      // Stable ordering, so a regenerated compose file does not churn.
      expect(found.map((s) => s.name), ['billing', 'orders', 'users']);
    });

    test('ignores a package with no routes directory', () {
      makeService('/repo/models', 'shared_models', routes: false);

      expect(const ServiceDiscovery().find(fs.directory('/repo')), isEmpty);
    });

    test('ignores a routes directory that is not a Revali package', () {
      // A frontend router or a docs folder would otherwise be reported as a
      // service.
      makeService('/repo/web', 'web_app', dependsOnRevali: false);

      expect(const ServiceDiscovery().find(fs.directory('/repo')), isEmpty);
    });

    test('does not descend into a service it already found', () {
      makeService('/repo/users', 'users_service');
      makeService('/repo/users/.revali/revali_client', 'generated_client');

      final found = const ServiceDiscovery().find(fs.directory('/repo'));

      expect(found, hasLength(1));
      expect(found.single.name, 'users_service');
    });

    test('skips generated and vendor directories', () {
      makeService('/repo/.dart_tool/thing', 'cached');
      makeService('/repo/node_modules/thing', 'vendored');
      makeService('/repo/build/thing', 'built');

      expect(const ServiceDiscovery().find(fs.directory('/repo')), isEmpty);
    });

    test('reports whether a Dockerfile exists yet', () {
      makeService('/repo/a', 'a', dockerfile: true);
      makeService('/repo/b', 'b');

      final found = const ServiceDiscovery().find(fs.directory('/repo'));

      expect(found.first.hasDockerfile, isTrue);
      expect(found.last.hasDockerfile, isFalse);
    });

    test('finds a service at the root itself', () {
      makeService('/repo', 'single_service');

      final found = const ServiceDiscovery().find(fs.directory('/repo'));

      expect(found.single.relativePath, '.');
    });
  });

  group('composeFile', () {
    test('says so when there is nothing to generate', () {
      expect(composeFile(const []), contains('No Revali services'));
    });

    test('gives each service its own port, in order', () {
      makeService('/repo/a', 'a', dockerfile: true);
      makeService('/repo/b', 'b', dockerfile: true);

      final yaml = composeFile(
        const ServiceDiscovery().find(fs.directory('/repo')),
      );

      expect(yaml, contains("PORT: '8080'"));
      expect(yaml, contains("- '8080:8080'"));
      expect(yaml, contains("PORT: '8081'"));
      expect(yaml, contains("- '8081:8081'"));
    });

    test('honours a custom base port', () {
      makeService('/repo/a', 'a', dockerfile: true);

      final yaml = composeFile(
        const ServiceDiscovery().find(fs.directory('/repo')),
        basePort: 9000,
      );

      expect(yaml, contains("PORT: '9000'"));
    });

    test('points the build at the service directory', () {
      makeService('/repo/services/users', 'users', dockerfile: true);

      final yaml = composeFile(
        const ServiceDiscovery().find(fs.directory('/repo')),
      );

      expect(yaml, contains('context: services/users'));
      expect(yaml, contains('dockerfile: .revali/build/Dockerfile'));
    });

    test('flags a service with no Dockerfile rather than omitting it', () {
      makeService('/repo/a', 'a');

      final yaml = composeFile(
        const ServiceDiscovery().find(fs.directory('/repo')),
      );

      // Silently dropping it would be harder to notice than a build that
      // fails and says why.
      expect(yaml, contains('a:'));
      expect(yaml, contains('No Dockerfile yet'));
    });

    test('disambiguates services that share a package name', () {
      // Package names are not unique across a repo -- several example or test
      // services can legitimately be called `hello`. A duplicate compose key
      // does not error: the later entry silently replaces the earlier one and
      // a service vanishes from the system it was meant to describe.
      makeService('/repo/examples/hello', 'hello', dockerfile: true);
      makeService('/repo/examples/other', 'hello', dockerfile: true);
      makeService('/repo/users', 'users', dockerfile: true);

      final yaml = composeFile(
        const ServiceDiscovery().find(fs.directory('/repo')),
      );

      expect(yaml, contains('examples-hello:'));
      expect(yaml, contains('examples-other:'));
      // The one with a unique name keeps it.
      expect(yaml, contains('  users:'));
      expect(yaml, isNot(contains('  hello:')));
    });

    test('says nothing about Dockerfiles that exist', () {
      makeService('/repo/a', 'a', dockerfile: true);

      final yaml = composeFile(
        const ServiceDiscovery().find(fs.directory('/repo')),
      );

      expect(yaml, isNot(contains('No Dockerfile yet')));
    });
  });
}
