import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

Element? typeFromIterable(DartType type) {
  if (type is! InterfaceType) {
    return null;
  }

  final element = type.element;

  if (element is! ClassElement || type.typeArguments.isEmpty) {
    return null;
  }

  InterfaceType? iterableType;

  for (final supertype in element.allSupertypes) {
    if (supertype.getDisplayString().startsWith('Iterable')) {
      iterableType = supertype;
      break;
    }
  }

  if (iterableType == null) {
    return null;
  }

  final iterableTypeArg = type.typeArguments.first;

  if (iterableTypeArg is! InterfaceType) {
    return null;
  }

  return iterableTypeArg.element;
}
