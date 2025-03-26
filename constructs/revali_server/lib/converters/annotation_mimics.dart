import 'package:revali_server/converters/base_annotations.dart';
import 'package:revali_server/converters/server_mimic.dart';

class AnnotationMimics implements BaseAnnotations<ServerMimic> {
  @override
  List<ServerMimic> catchers = [];

  @override
  List<ServerMimic> guards = [];

  @override
  List<ServerMimic> interceptors = [];

  @override
  List<ServerMimic> middlewares = [];

  @override
  List<ServerMimic> combines = [];

  List<ServerMimic> get all => [
        ...catchers,
        ...guards,
        ...interceptors,
        ...middlewares,
        ...combines,
      ];
}
