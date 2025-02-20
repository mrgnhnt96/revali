// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/creators/create_request.dart';
import 'package:revali_client_gen/makers/creators/parse_json.dart';
import 'package:revali_client_gen/models/client_method.dart';

List<Code> createStreamCall(ClientMethod method) {
  return [
    createRequest(method),
    const Code(''),
    declareFinal('stream')
        .assign(
          refer('response').property('transform').call([refer('utf8.decoder')]),
        )
        .statement,
    const Code(''),
    refer('yield* stream').property('map').call([
      Method(
        (b) => b
          ..requiredParameters.add(
            Parameter((b) => b..name = 'event'),
          )
          ..body = Block.of([
            parseJson(method, 'event').code,
          ]),
      ).closure,
    ]).statement,
  ];
}
