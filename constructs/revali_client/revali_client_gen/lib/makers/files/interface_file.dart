import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/files/controller_interface_file.dart';
import 'package:revali_client_gen/models/client_server.dart';
import 'package:revali_construct/revali_construct.dart';

DartFile interfaceFile(ClientServer server, String Function(Spec) formatter) {
  final imports = server.allImports(
    additionalPackages: [
      'package:revali_client/revali_client.dart',
      if (server.hasWebsockets)
        'package:web_socket_channel/web_socket_channel.dart',
    ],
  );

  final typedefs = [
    if (server.hasWebsockets)
      TypeDef(
        (b) => b
          ..name = 'WebSocketConnect'
          ..definition = CodeExpression(
            Block.of([
              refer('WebSocketChannel').code,
              FunctionType(
                (b) => b
                  ..requiredParameters.addAll([
                    TypeReference((b) => b..symbol = 'Uri'),
                  ])
                  ..namedParameters.addAll({
                    'protocols': TypeReference(
                      (b) => b
                        ..symbol = 'Iterable'
                        ..isNullable = true
                        ..types.add(refer('String')),
                    ),
                  }),
              ).code,
            ]),
          ),
      ),
  ].map(formatter).join('\n');

  return DartFile(
    basename: 'interfaces',
    content:
        '''
$imports
export 'package:revali_client/src/storage.dart';
$typedefs
''',
    parts: [
      for (final controller in server.controllers)
        if (!controller.isExcluded)
          controllerInterfaceFile(controller, formatter),
    ],
    segments: ['lib'],
  );
}
