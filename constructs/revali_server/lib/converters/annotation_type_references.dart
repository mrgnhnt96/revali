import 'package:revali_server/converters/base_annotations.dart';
import 'package:revali_server/converters/server_type_reference.dart';

class AnnotationTypeReferences implements BaseAnnotations<ServerTypeReference> {
  @override
  List<ServerTypeReference> catchers = [];

  @override
  List<ServerTypeReference> guards = [];

  @override
  List<ServerTypeReference> interceptors = [];

  @override
  List<ServerTypeReference> middlewares = [];

  @override
  List<ServerTypeReference> combines = [];

  List<ServerTypeReference> get all => [
        ...catchers,
        ...guards,
        ...interceptors,
        ...middlewares,
        ...combines,
      ];
}
