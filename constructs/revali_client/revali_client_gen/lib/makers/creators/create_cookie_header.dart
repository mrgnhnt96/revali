// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/enums/parameter_position.dart';
import 'package:revali_client_gen/makers/utils/create_map.dart';
import 'package:revali_client_gen/makers/utils/type_extensions.dart';
import 'package:revali_client_gen/models/client_param.dart';

Code createCookieHeader(Iterable<ClientParam> params) {
  assert(params.isNotEmpty, 'No cookie params found');
  assert(
    params.every((param) => param.position == ParameterPosition.cookie),
    'Not all params are cookie params',
  );

  return createMap(
    Map.fromEntries(params.map(_createEntry)),
    ref: (ref) {
      return ref
          .property('entries')
          .property('map')
          .call([
            Method(
              (b) => b
                ..lambda = true
                ..requiredParameters.add(
                  Parameter(
                    (b) => b..name = 'e',
                  ),
                )
                ..body = literalString(r'${e.key}=${e.value}').code,
            ).closure,
          ])
          .property('join')
          .call([literal('; ')])
          .code;
    },
  ).code;
}

MapEntry<Object, Code> _createEntry(ClientParam param) {
  final access = switch (param.access) {
    [final String access] => access,
    _ => param.name,
  };

  return MapEntry(
    access,
    refer('_storage')
        .index(literal(access))
        .awaited
        .ifNullThen(
          refer((Exception).name)
              .newInstance(
                [literal('Missing cookie: $access')],
              )
              .thrown
              .parenthesized,
        )
        .code,
  );
}
