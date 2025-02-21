import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:revali_client_gen/models/client_server.dart';
import 'package:revali_client_gen/models/settings.dart';
import 'package:revali_construct/revali_construct.dart';

AnyFile pubspecFile(ClientServer server, Settings settings) {
  final serverClient = Isolate.resolvePackageUriSync(
    Uri.parse('package:revali_client/'),
  ).toString();

  final imports = server.controllers
      .expand(
        (e) => e.methods.expand(
          (e) => e.returnType.imports.expand(
            (e) => e?.packages.toList() ?? <String>[],
          ),
        ),
      )
      .toSet();

  final packages = <(String, String)>{('revali_client', serverClient)};
  for (final import in imports) {
    final [_, String packagePath] = import.split(':');
    final [String package, ...] = packagePath.split('/');

    final resolved = Isolate.resolvePackageUriSync(
      Uri.parse('package:$package/'),
    ).toString();

    packages.add((package, resolved));
  }

  final dependencies = StringBuffer();

  switch (server.hasWebsockets) {
    case true:
      dependencies.writeln('  web_socket_channel: ^3.0.2');

    case false:
      break;
  }

  for (final (package, path) in packages) {
    final segments = path.split('/');
    switch ((
      segments.contains('hosted'),
      segments.reversed.toList()..removeWhere((e) => e.isEmpty),
    )) {
      case (true, [_, final String package, ...]):
        final version = package.replaceAll('revali_client-', '');

        dependencies.writeln('  $package: $version');
      case (false, _):
        Iterable<String> clean() sync* {
          for (final part in segments.skip(1)) {
            if (part.isEmpty) continue;
            if (part == 'lib') continue;
            yield part;
          }
        }

        final path = p.joinAll([p.separator, ...clean()]);

        dependencies.writeln('''
  $package:
    path: $path''');
    }
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
