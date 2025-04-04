import 'package:revali_router_core/revali_router_core.dart';

abstract interface class BaseParameterAnnotation {
  String? get name;
  AnnotationType get type;
}
