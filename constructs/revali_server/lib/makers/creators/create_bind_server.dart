import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart' hide Method;
import 'package:revali_server/makers/utils/type_extensions.dart';

/// Emits `_bindServer`, which binds the HTTP listener for the generated server.
///
/// When `app.host` is `localhost`, binds dual-stack on
/// `InternetAddress.anyIPv6`
/// with `v6Only: false` so IPv4 clients can connect on platforms where
/// `HttpServer.bind('localhost', …)` would land on IPv6 loopback only.
Method createBindServerMethod() {
  return Method(
    (b) => b
      ..name = '_bindServer'
      ..returns = TypeReference(
        (p) => p
          ..symbol = (Future).name
          ..types.add(refer((HttpServer).name)),
      )
      ..modifier = MethodModifier.async
      ..requiredParameters.add(
        Parameter(
          (p) => p
            ..name = 'app'
            ..type = refer((AppConfig).name),
        ),
      )
      ..optionalParameters.addAll([
        Parameter(
          (p) => p
            ..name = 'providedServer'
            ..named = true
            ..type = refer('${(HttpServer).name}?'),
        ),
        Parameter(
          (p) => p
            ..name = 'shared'
            ..named = true
            ..defaultTo = const Code('false')
            ..type = refer('bool'),
        ),
      ])
      ..body = Block.of([
        const Code('''
if (providedServer != null) {
  return providedServer;
}

final host = switch (app.host) {
  'localhost' => InternetAddress.anyIPv6,
  final String h => h,
};

final v6Only = app.host != 'localhost';


if (app.securityContext case final context?) {
  return await HttpServer.bindSecure(
    host,
    app.port,
    context,
    requestClientCertificate: app.requestClientCertificate,
    v6Only: v6Only,
    shared: shared,
  );
}

return await HttpServer.bind(host, app.port, shared: shared, v6Only: v6Only);
'''),
      ]),
  );
}

Expression bindServerCall({
  required Expression app,
  required Expression providedServer,
  required bool shared,
}) {
  return refer('_bindServer').call(
    [app],
    {'providedServer': providedServer, if (shared) 'shared': literalTrue},
  );
}
