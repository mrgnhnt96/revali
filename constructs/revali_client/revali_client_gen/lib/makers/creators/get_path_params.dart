// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_client_gen/makers/utils/type_extensions.dart';
import 'package:revali_client_gen/models/client_method.dart';

// The parameters contained within the path of the method
//
// e.g. /shop/:id/item/:itemId
//
// The path params are :id and :itemId
Iterable<Parameter> getPathParams(ClientMethod method) sync* {
  for (final param in method.params) {
    yield Parameter(
      (b) => b
        ..name = param
        ..named = true
        ..required = true
        ..type = refer((String).name),
    );
  }
}
