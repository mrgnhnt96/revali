import 'package:revali_router_core/context/context.dart';

abstract class BindContext implements Context {
  const BindContext();

  /// The name of the parameter that corresponds to the annotation.
  ///
  /// Example:
  ///
  /// ```dart
  /// @Body('userId') String id,
  /// ```
  ///
  ///  would yield "id"
  String get nameOfParameter;

  /// The expected type for the parameter.
  ///
  /// Example:
  ///
  /// ```dart
  /// @Body('userId') String id,
  /// ```
  ///
  /// would yield `String`
  Type get parameterType;
}
