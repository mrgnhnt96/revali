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
    this.ignoreGenerics = false,
  }) : classType = '$classType';

  @override
  final String classType;
  @override
  final String package;
  @override
  final bool ignoreGenerics;
  final void Function(DartObject object, ElementAnnotation annotation) convert;
}

class Matcher {
  const Matcher({
    required Type classType,
    required this.package,
    this.ignoreGenerics = false,
  }) : classType = '$classType';

  const Matcher.any(
    this.classType, {
    this.ignoreGenerics = false,
  }) : package = null;

  final String classType;
  final String? package;
  final bool ignoreGenerics;
}

class NonMatch {
  const NonMatch({
    required this.convert,
    this.ignore = const [],
  });

  final Iterable<Matcher> ignore;

  final void Function(DartObject object, ElementAnnotation annotation) convert;
}
