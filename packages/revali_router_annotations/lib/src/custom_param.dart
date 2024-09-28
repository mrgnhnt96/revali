import 'dart:async';

import 'package:revali_router_core/custom_param/custom_param_context.dart';

/// A custom parameter that can be used in routes.
///
/// The type [T] is the type to be returned from the [bind] method.
abstract interface class CustomParam<T> {
  const CustomParam();

  FutureOr<T> bind(CustomParamContext context);
}
