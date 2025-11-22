import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/creators/create_interface_content.dart';
import 'package:revali_client_gen/models/client_controller.dart';
import 'package:revali_construct/revali_construct.dart';

PartFile controllerInterfaceFile(
  ClientController controller,
  String Function(Spec) formatter,
) {
  final content = createInterfaceContent(controller);

  return PartFile(
    content: formatter(content),
    path: ['lib', 'src', 'interfaces', controller.interfaceName.toSnakeCase()],
  );
}
