import 'package:analyzer/dart/constant/value.dart';

class AppAnnotation {
  const AppAnnotation({required this.flavor});

  factory AppAnnotation.fromAnnotation(DartObject annotation) {
    final flavor = annotation.getField('flavor')?.toStringValue();

    return AppAnnotation(flavor: flavor);
  }

  final String? flavor;
}
