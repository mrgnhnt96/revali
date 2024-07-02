import 'package:revali_annotations/enums/param_type.dart';

class ArgumentMetadata {
  const ArgumentMetadata(
    this.type,
    this.data,
  );

  /// Indicates whether argument is a body, query, param, or custom parameter
  final ParamType type;

  /// String passed as an argument to the decorator.
  /// Example: `@Body('userId')` would yield `userId`
  final String data;
}
