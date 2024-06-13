import 'package:zora_gen/models/meta_method.dart';
import 'package:zora_gen/models/meta_middleware.dart';
import 'package:zora_gen/models/meta_param.dart';

class MetaRoute {
  const MetaRoute({
    required this.className,
    required this.filePath,
    required this.path,
    required this.methods,
    required this.middlewares,
    required this.params,
    required this.constructorName,
  });

  final String path;
  final String filePath;
  final String className;
  final String constructorName;
  final Iterable<MetaMethod> methods;
  final Iterable<MetaMiddleware> middlewares;
  final Iterable<MetaParam> params;
}
