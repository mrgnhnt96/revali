import 'package:change_case/change_case.dart';
import 'package:revali_construct/revali_construct.dart';

extension MetaMethodX on MetaMethod {
  String handlerName(MetaRoute parent) {
    final method = path ?? '';
    final joined = '${parent.path}_$method';

    return '_${joined.toNoCase().toCamelCase()}';
  }

  String get cleanPath => '/${path ?? ''}'.replaceAll('//', '/');

  String get formattedPath {
    final path = this.cleanPath;

    final segments = path.split('/');

    final formattedSegments = segments.map((segment) {
      if (segment.startsWith(':')) {
        final part = segment.substring(1);
        return '<$part>';
      }

      return segment;
    });

    return formattedSegments.join('/');
  }
}
