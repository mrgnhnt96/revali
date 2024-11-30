import 'package:code_builder/code_builder.dart';
import 'package:revali_server/converters/server_mimic.dart';

Expression createMimic(ServerMimic mimic) =>
    CodeExpression(Code('const ${mimic.instance}'));
