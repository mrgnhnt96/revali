import 'package:zora_core/models/request.dart';

class Route {
  const Route({
    required this.path,
    required this.methods,
  });

  final String path;
  final Iterable<Method> methods;
}
