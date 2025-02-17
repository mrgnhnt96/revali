// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:server_client_gen/makers/utils/type_extensions.dart';
import 'package:server_client_gen/models/client_method.dart';

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
