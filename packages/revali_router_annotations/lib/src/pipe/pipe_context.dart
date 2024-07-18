import 'package:revali_router_core/revali_router_core.dart';

import 'annotation_type.dart';

abstract class PipeContext<T> {
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
  T get annotationArgument;

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

  ReadOnlyDataHandler get data;

  ReadOnlyMeta get meta;
}
