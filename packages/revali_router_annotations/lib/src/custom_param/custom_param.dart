import 'dart:async';

import 'package:revali_router_annotations/src/custom_param/custom_param_context.dart';

/// A custom parameter that can be used in routes.
///
/// The type [T] is the type to be returned from the [parse] method.
abstract class CustomParam<T> {
  const CustomParam();

  FutureOr<T> parse(CustomParamContext context);
}
