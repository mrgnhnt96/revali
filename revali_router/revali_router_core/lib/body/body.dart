import 'package:revali_router_core/body/body_data.dart';

abstract base class Body extends BodyData {
  /// Replaces the entire body with the given data.
  Future<void> replace(Object? data);

  /// Adds/Replaces a single key in the body with the given data.
  void operator []=(String key, Object? data);

  /// Adds the given data to the body.
  ///
  /// If the body is not a list, this will throw an exception.
  void add(Object? data);
}
