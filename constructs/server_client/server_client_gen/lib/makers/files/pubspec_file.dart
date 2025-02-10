import 'package:revali_construct/revali_construct.dart';

import '../../models/client_server.dart';

AnyFile pubspecFile(ClientServer server) {
  // TODO: Leverage options to set properties
  return const AnyFile(
    basename: 'pubspec',
    extension: 'yaml',
    content: '''
name: client_server
description: A client server for the server.

environment:
  sdk: '>=3.5.0 <4.0.0'
''',
  );
}
