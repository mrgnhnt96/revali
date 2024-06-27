// ignore_for_file: directives_ordering
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:io' as _i5;
import 'dart:isolate' as _i3;

import 'package:zora/zora.dart' as _i4;
import 'package:zora_construct/zora_construct.dart' as _i1;
import 'package:zora_shelf/main.dart' as _i2;

final _constructs = <_i1.ConstructMaker>[
  _i1.ConstructMaker(
    package: 'zora_shelf',
    isRouter: true,
    name: 'shelf',
    maker: _i2.shelfConstruct,
  )
];
const _routes = '/Users/morgan/Documents/develop.nosync/zora/examples/demo';
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
