// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:server_client_gen/makers/creators/create_request.dart';
import 'package:server_client_gen/makers/creators/parse_json.dart';
import 'package:server_client_gen/models/client_method.dart';

List<Code> createFutureCall(ClientMethod method) {
  return [
    createRequest(method),
    const Code(''),
    declareFinal('body')
        .assign(
          refer('response')
              .property('transform')
              .call([refer('utf8.decoder')])
              .property('join')
              .call([])
              .awaited,
        )
        .statement,
    if (!method.returnType.isVoid) ...[
      const Code(''),
      parseJson(method, 'body').code,
    ],
  ];
}
