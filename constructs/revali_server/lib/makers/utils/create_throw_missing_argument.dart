import 'package:code_builder/code_builder.dart';
import 'package:revali_server/converters/base_parameter_annotation.dart';
import 'package:revali_server/converters/has_pipe.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/makers/creators/create_missing_argument_exception.dart';

Expression? createThrowMissingArgument(
  BaseParameterAnnotation annotation,
  ServerParam param, {
  String? location,
}) {
  final at = '@${annotation.type.name}';
  final atLocation = switch (location) {
    null => at,
    final location => '$at#$location',
  };
  final throwException = createMissingArgumentException(
    key: annotation.name ?? param.name,
    location: atLocation,
  ).thrown.parenthesized;

  if (annotation case HasPipe(:final pipe?)) {
    if (param.hasDefaultValue) {
      return null;
    }

    if (pipe.convertFrom.isNullable) {
      return null;
    }

    return throwException;
  }

  if (param.type.isNullable) {
    return null;
  }

  if (param.hasDefaultValue) {
    return null;
  }

  return throwException;
}
