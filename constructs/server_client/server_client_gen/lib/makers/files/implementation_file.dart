import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/revali_construct.dart';

import '../../models/client_controller.dart';
import '../creators/create_impl_content.dart';

Iterable<DartFile> implementationFile(
  ClientController controller,
  String Function(Spec) formatter,
) sync* {
  final content = createImplContent(controller);

  yield DartFile(
    basename: controller.interfaceName.toSnakeCase(),
    content: formatter(content),
    segments: ['lib', 'src', 'impls'],
  );
}
