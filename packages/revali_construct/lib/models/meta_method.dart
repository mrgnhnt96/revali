import 'dart:core';

import 'package:revali_construct/types/annotation_getter.dart';

import 'meta_param.dart';
import 'meta_return_type.dart';

class MetaMethod {
  const MetaMethod({
    required this.name,
    required this.method,
    required this.path,
    required this.params,
    required this.returnType,
    required this.annotationsMapper,
    required this.isWebSocket,
  });

  final String name;
  final String method;
  final String? path;
  final Iterable<MetaParam> params;
  final MetaReturnType returnType;
  final AnnotationMapper annotationsMapper;
  final bool isWebSocket;
}
