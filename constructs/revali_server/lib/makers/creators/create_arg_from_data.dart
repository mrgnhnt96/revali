import 'package:code_builder/code_builder.dart';

Expression createDataVar() {
  return refer('context').property('data').property('get').call([]);
}
