import 'package:revali_construct/revali_construct.dart';

class ServerAppAnnotation {
  const ServerAppAnnotation({
    required this.flavor,
  });

  factory ServerAppAnnotation.fromMeta(AppAnnotation app) {
    return ServerAppAnnotation(
      flavor: app.flavor,
    );
  }

  final String? flavor;
}
