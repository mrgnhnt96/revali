import 'package:code_builder/code_builder.dart';

Expression createGetFromDi() {
  return refer('di').property('get').call([]);
}
