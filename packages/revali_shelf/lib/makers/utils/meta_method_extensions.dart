import 'package:change_case/change_case.dart';
import 'package:revali_construct/revali_construct.dart';

extension MetaMethodX on MetaMethod {
  String handlerName(MetaRoute parent) {
    final method = path ?? '';
    final joined = '${parent.path}_$method';

    return '_${joined.toNoCase().toCamelCase()}';
  }

  String get cleanPath => '/${path ?? ''}'.replaceAll('//', '/');
}
