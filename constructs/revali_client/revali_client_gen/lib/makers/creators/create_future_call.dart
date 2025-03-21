// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/creators/create_request.dart';
import 'package:revali_client_gen/makers/creators/parse_json.dart';
import 'package:revali_client_gen/models/client_method.dart';
import 'package:revali_client_gen/models/client_type.dart';

List<Code> createFutureCall(ClientMethod method) {
  final returnType = method.returnType;

  final coreType = switch (returnType) {
    ClientType(typeArguments: [final type]) => type,
    _ => returnType,
  };

  final fromJson = parseJson(returnType, refer('body'));

  final body = refer('response')
      .property('transform')
      .call([refer('utf8.decoder')])
      .property('join')
      .call([])
      .awaited;

  return [
    createRequest(method),
    const Code(''),
    if (coreType.isBytes)
      refer('response').property('toList').call([]).awaited.returned.statement
    else if (fromJson == null)
      body.returned.statement
    else ...[
      declareFinal('body').assign(body).statement,
      const Code(''),
      fromJson,
    ],
  ];
}
