import 'package:code_builder/code_builder.dart';
import 'package:revali_server/revali_server.dart';

Expression mimic(ServerMimic mimic) => CodeExpression(Code(mimic.instance));
