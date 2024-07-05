import 'package:revali_router/src/data/read_only_data_handler.dart';
import 'package:revali_router/src/meta/read_only_meta.dart';
import 'package:revali_router/src/pipe/param_type.dart';

abstract class PipeContext<T> {
  const PipeContext();

  /// Indicates whether argument is a body, query, param, or custom parameter
  ParamType get type;

  /// String passed as an argument to the decorator.
  /// Example: `@Body('userId')` would yield `userId`
  T get arg;

  /// the name of the parameter that corresponds to the pipe annotation.
  String get paramName;

  ReadOnlyDataHandler get data;

  ReadOnlyMeta get meta;
}
