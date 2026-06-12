import 'package:revali_construct/revali_construct.dart';
import 'package:revali_swagger/models/swagger_settings.dart';
import 'package:revali_swagger/src/swagger_construct.dart';

// ignore: non_constant_identifier_names
Construct swaggerConstruct([ConstructOptions? options]) {
  final settings = SwaggerSettings.fromJson(options?.values ?? {});
  return SwaggerConstruct(settings);
}
