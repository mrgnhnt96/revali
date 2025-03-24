import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/enums/parameter_position.dart';
import 'package:revali_client_gen/makers/utils/create_map.dart';
import 'package:revali_client_gen/models/client_param.dart';

Expression createQueryArg(Iterable<ClientParam> params) {
  assert(params.isNotEmpty, 'No query params found');
  assert(
    params.every((param) => param.position == ParameterPosition.query),
    'Not all params are query params',
  );

  return createMap(
    {
      for (final param in params)
        switch (param.access) {
          [final String access] => access,
          _ => param.name
        }: refer(param.name).code,
    },
  );
}
