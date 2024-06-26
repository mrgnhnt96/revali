// ignore_for_file: directives_ordering
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:io' as _i5;
import 'dart:isolate' as _i3;

import 'package:zora_gen/zora_gen.dart' as _i4;
import 'package:zora_gen_core/zora_gen_core.dart' as _i1;
import 'package:zora_shelf/main.dart' as _i2;

final _constructs = <_i1.Construct Function(_i1.ConstructOptions?)>[
  _i2.shelfConstruct
];
const _routes =
    '/Users/morgan/Documents/develop.nosync/zora/examples/demo/routes';
void main(
  List<String> args, [
  _i3.SendPort? sendPort,
]) async {
  final result = await _i4.run(
    ['dev'],
    constructs: _constructs,
    path: _routes,
  );

  sendPort?.send(result);

  _i5.exitCode = result;
}