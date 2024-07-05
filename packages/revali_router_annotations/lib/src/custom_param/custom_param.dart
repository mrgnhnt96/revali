import 'package:revali_router_annotations/custom_param/custom_param_context.dart';

/// A custom parameter that can be used in routes.
///
/// The type [T] is the type to be returned from the [parse] method.
abstract class CustomParam<T> {
  const CustomParam();

  T parse(CustomParamContext context);
}
