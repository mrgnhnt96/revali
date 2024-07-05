import 'package:analyzer/dart/constant/value.dart';
import 'package:revali_shelf/revali_shelf.dart';

class ShelfCatches {
  const ShelfCatches({
    required this.catchers,
  });

  factory ShelfCatches.fromDartObject(DartObject dartObject, String source) {
    final types = dartObject.getField('catchers')?.toListValue();
    if (types == null || types.isEmpty) {
      return const ShelfCatches(catchers: []);
    }

    return ShelfCatches(
      catchers:
          types.map((e) => ShelfExceptionCatcher.fromDartObject(e, source)),
    );
  }

  final Iterable<ShelfExceptionCatcher> catchers;
}
