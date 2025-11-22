import 'dart:async';

import 'package:revali_router_core/revali_router_core.dart';

/// A custom parameter that can be used in routes.
///
/// The type [T] is the type to be returned from the [bind] method.
abstract interface class Bind<T> {
  const Bind();

  FutureOr<T> bind(BindContext context);
}
