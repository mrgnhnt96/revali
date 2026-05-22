import 'package:code_builder/code_builder.dart';

Expression createGetFromDi() {
  return refer('RequestScopedDI').property('getFrom').call([refer('di')]);
}
