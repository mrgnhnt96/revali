import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_shelf/converters/shelf_class.dart';
import 'package:revali_shelf/converters/shelf_reflect.dart';

class ShelfPipe {
  const ShelfPipe({
    required this.pipe,
    required this.reflect,
  });

  factory ShelfPipe.fromType(DartType type) {
    ShelfReflect? reflect;

    if (type.element case final ClassElement element?) {
      final superPipe = element.allSupertypes.firstWhere((element) {
        return element.element.name == 'Pipe';
      });

      final firstTypeArg = superPipe.typeArguments.first;

      if (firstTypeArg.element is ClassElement) {
        reflect = ShelfReflect.fromElement(firstTypeArg.element!);
      }
    }

    return ShelfPipe(
      pipe: ShelfClass.fromType(type, superType: Pipe),
      reflect: reflect,
    );
  }

  final ShelfClass pipe;
  final ShelfReflect? reflect;
}
