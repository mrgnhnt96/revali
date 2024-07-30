// ignore_for_file: unnecessary_parenthesis

import 'package:code_builder/code_builder.dart';
import 'package:revali_router/revali_router.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';

Expression createMissingArgumentException({
  required String key,
  required String location,
}) {
  return refer((MissingArgumentException).name).constInstance(
    [],
    {
      'key': literalString(key),
      'location': literalString(location),
    },
  );
}
