import 'package:revali_construct/revali_construct.dart';

class ShelfAppAnnotation {
  const ShelfAppAnnotation({
    required this.flavor,
  });

  factory ShelfAppAnnotation.fromMeta(AppAnnotation app) {
    return ShelfAppAnnotation(
      flavor: app.flavor,
    );
  }

  final String? flavor;
}
