import 'package:revali_router_core/revali_router_core.dart';

import 'param_type.dart';

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
