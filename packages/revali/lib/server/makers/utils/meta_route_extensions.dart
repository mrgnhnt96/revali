import 'package:change_case/change_case.dart';
import 'package:revali_construct/revali_construct.dart';

extension MetaRouteX on MetaRoute {
  String get handlerName => path.toCamelCase();
  String get fileName => handlerName.toSnakeCase();

  String get cleanPath => '/$path'.replaceAll('//', '/');
}
