import 'package:revali_router/revali_router.dart';

abstract class CustomParamContext {
  const CustomParamContext();

  /// The name of the parameter that
  /// corresponds to the custom parameter annotation.
  String get name;

  /// The type of the parameter that
  /// corresponds to the custom parameter annotation.
  Type get type;

  ReadOnlyDataHandler get data;

  ReadOnlyMeta get meta;

  ReadOnlyRequestContext get request;

  ReadOnlyResponseContext get response;
}
