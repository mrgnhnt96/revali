import 'package:revali_router_core/revali_router_core.dart';

abstract class BindContext {
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

  ReadOnlyData get data;

  ReadOnlyMeta get meta;

  ReadOnlyRequest get request;

  ReadOnlyResponse get response;
}
