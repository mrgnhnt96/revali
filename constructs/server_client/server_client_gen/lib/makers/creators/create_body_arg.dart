import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart';
import 'package:server_client_gen/enums/parameter_position.dart';
import 'package:server_client_gen/makers/utils/client_param_extensions.dart';
import 'package:server_client_gen/makers/utils/create_map.dart';
import 'package:server_client_gen/models/client_param.dart';

Expression createBodyArg(Iterable<ClientParam> params) {
  assert(params.isNotEmpty, 'No body params found');
  assert(
    params.every((param) => param.position == ParameterPosition.body),
    'Not all params are body params',
  );

  Expression createSingle(ClientParam param) {
    if (param.access.isEmpty) {
      return refer(param.name);
    }

    return createMap(_createMapWithKeys(param.access, param));
  }

  if (params case [final ClientParam single]) {
    return createSingle(single);
  }

  if (params.firstWhereOrNull((e) => e.access.isEmpty)
      case final ClientParam param) {
    return createSingle(param);
  }

  final roots = params.roots();

  final entries = <String, dynamic>{};

  for (final param in params) {
    if (!params.needsAssignment(param, roots)) {
      continue;
    }

    final map = _createMapWithKeys(param.access, param);

    entries.addEntries(map.entries);
  }

  return createMap(entries);
}

Map<String, dynamic> _createMapWithKeys(
  List<String> keys,
  ClientParam param,
) {
  if (keys.isEmpty) {
    return {};
  }

  final key = keys.first;
  final nestedMap = switch (_createMapWithKeys(keys.sublist(1), param)) {
    final result when result.isNotEmpty => result,
    _ => null,
  };

  return {
    key: nestedMap ?? refer(param.name).code,
  };
}
