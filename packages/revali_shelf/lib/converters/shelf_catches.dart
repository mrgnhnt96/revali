import 'package:analyzer/dart/constant/value.dart';
import 'package:revali_shelf/revali_shelf.dart';

class ShelfCatches {
  const ShelfCatches({
    required this.catchers,
  });

  factory ShelfCatches.fromDartObject(DartObject dartObject) {
    final types = dartObject.getField('catchers')?.toListValue();
    if (types == null || types.isEmpty) {
      return const ShelfCatches(catchers: []);
    }

    return ShelfCatches(
      catchers: types.map(ShelfExceptionCatcher.fromDartObject),
    );
  }

  final Iterable<ShelfExceptionCatcher> catchers;
}
