import 'dart:io';

import 'package:test/test.dart';

import '../.revali/server/server.dart';
import '../routes/apps/test_app.dart';

void main() {
  group('environment-driven config on a generated server', () {
    test('binds a non-const app built from the environment', () async {
      // The regression this guards: `AppConfig.fromEnv` cannot be const, so
      // generated code has to instantiate the app accordingly. When the
      // constructor existed only on the core AppConfig, every real app failed
      // to compile here while the unit tests passed.
      final server = await createServer();
      addTearDown(() => server.close(force: true));

      expect(server.port, isNot(0), reason: 'the OS should have assigned one');
    });

    test('binds every interface, not just loopback', () async {
      final server = await createServer();
      addTearDown(() => server.close(force: true));

      // fromEnv defaults to 0.0.0.0 rather than localhost: a server bound to
      // loopback inside a container refuses every request from outside while
      // looking perfectly healthy.
      expect(server.address.address, InternetAddress.anyIPv4.address);
    });

    test('the app class itself reports the fromEnv defaults', () {
      final app = TestApp();

      expect(app.host, '0.0.0.0');
      // defaultPort: 0 in the fixture, so the OS picks one at bind time.
      expect(app.port, 0);
    });
  });
}
