import 'package:revali_router_core/data/read_only_data.dart';
import 'package:revali_router_core/meta/read_only_meta.dart';
import 'package:revali_router_core/pipe/annotation_type.dart';

abstract class PipeContext {
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

  ReadOnlyData get data;

  ReadOnlyMeta get meta;
}
