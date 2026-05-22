import 'package:code_builder/code_builder.dart';

Expression createIpVar() {
  return refer('context').property('request').property('ip');
}
