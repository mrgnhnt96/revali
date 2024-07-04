import 'package:analyzer/dart/constant/value.dart';

typedef AnnotationGetter = Iterable<DartObject> Function({
  required Type classType,
  required String package,
});
