import 'package:code_builder/code_builder.dart';
import 'package:revali_server/converters/server_parent_route.dart';
import 'package:revali_server/makers/creators/create_get_from_di.dart';
import 'package:revali_server/makers/utils/get_params.dart';

Spec createParentRef(ServerParentRoute route) {
  final (:positioned, :named) = getParams(
    route.params,
    defaultExpression: createGetFromDi(),
  );

  return refer(route.handlerName).call([
    refer(route.className).newInstance(positioned, named),
    refer('di'),
  ]);
}
