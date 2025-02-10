import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/revali_construct.dart';

import '../../models/client_controller.dart';
import '../creators/create_interface_content.dart';

Iterable<DartFile> interfaceFile(
  ClientController controller,
  String Function(Spec) formatter,
) sync* {
  final content = createInterfaceContent(controller);

  yield DartFile(
    basename: controller.interfaceName.toSnakeCase(),
    content: formatter(content),
    segments: ['lib', 'src', 'interfaces'],
  );
}
