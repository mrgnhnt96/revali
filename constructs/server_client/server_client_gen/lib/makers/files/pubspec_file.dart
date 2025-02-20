import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:revali_construct/revali_construct.dart';
import 'package:server_client_gen/models/client_server.dart';
import 'package:server_client_gen/models/settings.dart';

AnyFile pubspecFile(ClientServer server, Settings settings) {
  final serverClientSegments = Isolate.resolvePackageUriSync(
    Uri.parse('package:server_client/'),
  ).toString().split(p.separator);

  final dependencies = StringBuffer();

  for (final dep in settings.dependencies) {
    var dependency = dep;
    if (!dep.contains(': ')) {
      dependency += ': any';
    }

    dependency = dependency.replaceAll('\n', '\n  ').trim();
    dependencies.writeln('''
  $dependency
''');
  }

  switch (server.hasWebsockets) {
    case true:
      dependencies.writeln('''
  web_socket_channel:
''');

    case false:
      break;
  }

  switch ((
    serverClientSegments.contains('hosted'),
    serverClientSegments.reversed.toList()..removeWhere((e) => e.isEmpty),
  )) {
    case (true, [_, final String package, ...]):
      final version = package.replaceAll('server_client-', '');

      dependencies.writeln('''
  server_client: $version
''');
    case (false, _):
      Iterable<String> clean() sync* {
        for (final part in serverClientSegments.skip(1)) {
          if (part.isEmpty) continue;
          if (part == 'lib') continue;
          yield part;
        }
      }

      final path = p.joinAll([p.separator, ...clean()]);

      dependencies.writeln('''
  server_client:
    path: $path
''');
  }

  return AnyFile(
    basename: 'pubspec',
    extension: 'yaml',
    content: '''
name: ${settings.packageName}

environment:
  sdk: '>=3.5.0 <4.0.0'

dependencies:
  http: ^1.3.0
$dependencies
''',
  );
}
