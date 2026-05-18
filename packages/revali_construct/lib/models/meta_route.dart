import 'package:analyzer/dart/element/element.dart';
import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_construct/models/meta_method.dart';
import 'package:revali_construct/models/meta_param.dart';
import 'package:revali_construct/types/annotation_getter.dart';

class MetaRoute {
  const MetaRoute({
    required this.className,
    required this.filePath,
    required this.path,
    required this.methods,
    required this.params,
    required this.constructorName,
    required this.annotationsFor,
    required this.element,
    required this.type,
  });

  final String path;
  final String filePath;
  final String className;
  final String constructorName;
  final List<MetaMethod> methods;
  final List<MetaParam> params;
  final AnnotationMapper annotationsFor;
  final ClassElement element;
  final InstanceType type;
}
