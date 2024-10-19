import 'package:code_builder/code_builder.dart';
import 'package:revali_server/revali_server.dart';

Expression createMimic(ServerMimic mimic) =>
    CodeExpression(Code('const ${mimic.instance}'));
