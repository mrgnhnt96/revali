import 'package:code_builder/code_builder.dart';
import 'package:revali_core/di/request_scoped_di.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';

Expression createGetFromDi() {
  return refer((RequestScopedDI).name).property('getFrom').call([refer('di')]);
}
