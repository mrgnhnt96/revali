import 'package:code_builder/code_builder.dart';
import 'package:revali_router_core/revali_router_core.dart';
import 'package:revali_server/converters/server_mimic.dart';
import 'package:revali_server/converters/server_reflect.dart';
import 'package:revali_server/makers/parts/mimic.dart';

Spec createReflect(ServerReflect possibleReflect) {
  final reflect = possibleReflect.valid;

  if (reflect == null) {
    return Code('');
  }

  Expression metaExp(MapEntry<String, Iterable<ServerMimic>> data) {
    final MapEntry(:key, value: meta) = data;

    var m = refer('m').index(literalString(key));

    for (final item in meta) {
      m = m.cascade('add').call([mimic(item)]);
    }

    return m;
  }

  return refer('$Reflect').newInstance(
    [
      refer(reflect.className),
    ],
    {
      'metas': Method(
        (p) => p
          ..requiredParameters.add(
            Parameter((p) => p..name = 'm'),
          )
          ..body = Block.of([
            for (final meta in reflect.metas.entries) metaExp(meta).statement,
          ]),
      ).closure,
    },
  );
}
