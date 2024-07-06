import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';

typedef AnnotationMapper = void Function({
  required List<OnMatch> onMatch,
  NonMatch? onNonMatch,
});

class OnMatch implements Matcher {
  const OnMatch({
    required Type classType,
    required this.package,
    required this.convert,
  }) : classType = '$classType';

  final String classType;
  final String package;
  final void Function(DartObject object, ElementAnnotation annotation) convert;
}

class Matcher {
  const Matcher({
    required Type classType,
    required this.package,
  }) : classType = '$classType';

  const Matcher.any(this.classType) : package = null;

  final String classType;
  final String? package;
}

class NonMatch {
  const NonMatch({
    this.ignore = const [],
    required this.convert,
  });

  final Iterable<Matcher> ignore;

  final void Function(DartObject object, ElementAnnotation annotation) convert;
}
