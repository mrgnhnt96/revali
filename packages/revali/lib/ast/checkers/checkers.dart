import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_construct/revali_construct.dart';

final controllerChecker = TypeChecker.fromName(
  '$Controller',
  packageName: 'revali_annotations',
);
final appChecker = TypeChecker.fromName(
  '$App',
  packageName: 'revali_annotations',
);
final methodChecker = TypeChecker.fromName(
  '$Method',
  packageName: 'revali_annotations',
);
