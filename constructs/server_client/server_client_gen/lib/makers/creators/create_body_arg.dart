import 'package:code_builder/code_builder.dart';
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

  if (params.where((e) => e.access.isEmpty) case final params
      when params.isNotEmpty) {
    if (params.length > 1) {
      if (!params.every((e) => e.type.name == params.first.type.name)) {
        throw Exception('Multiple body params with different types');
      }
    }

    return createSingle(params.first);
  }

  final roots = params.roots();

  void add(Map<String, dynamic> entries, String key, dynamic value) {
    final entry = entries[key];

    if (entry == null) {
      entries[key] = value;
      return;
    }

    if (entry is Map<String, dynamic>) {
      if (value is! Map<String, dynamic>) {
        throw Exception('Cannot merge map with non-map');
      }

      for (final MapEntry(:key, :value) in value.entries) {
        add(entry, key, value);
      }
    }
  }

  final entries = <String, dynamic>{};
  for (final param in params) {
    if (!params.needsAssignment(param, roots)) {
      continue;
    }

    final map = _createMapWithKeys(param.access, param);

    for (final MapEntry(:key, :value) in map.entries) {
      add(entries, key, value);
    }
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
