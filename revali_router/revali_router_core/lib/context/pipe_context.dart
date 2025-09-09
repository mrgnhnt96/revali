import 'package:revali_router_core/context/base_context.dart';
import 'package:revali_router_core/types/annotation_type.dart';

abstract class PipeContext implements BaseContext {
  const PipeContext();

  /// Indicates whether argument is a body, query, param, or custom parameter
  ///
  /// Example:
  /// ```dart
  /// @Body('userId', UserIdPipe) String id,
  /// ```
  ///
  /// would yield [AnnotationType.body]
  AnnotationType get type;

  /// The value passed as an argument to the annotation.
  ///
  /// Example:
  /// ```dart
  /// @Body('userId', UserIdPipe) String id,
  /// ```
  ///
  /// would yield "userId"
  dynamic get annotationArgument;

  /// The name of the parameter that corresponds to the pipe annotation.
  ///
  /// Example:
  ///
  /// ```dart
  /// @Body('userId', UserIdPipe) String id,
  /// ```
  ///
  ///  would yield "id"
  String get nameOfParameter;
}
