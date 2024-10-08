// ignore_for_file: directives_ordering
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:io' as _i5;
import 'dart:isolate' as _i3;

import 'package:revali/revali.dart' as _i4;
// ignore: depend_on_referenced_packages
import 'package:revali_construct/revali_construct.dart' as _i1;
import 'package:revali_server/server.dart' as _i2;

const _constructs = <_i1.ConstructMaker>[
  _i1.ConstructMaker(
    package: 'revali_server',
    isServer: true,
    isBuild: false,
    name: 'shelf',
    maker: _i2.serverConstruct,
  ),
];
const _routes = '/Users/morgan/Documents/develop.nosync/revali/examples/demo';
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
