import 'dart:core';

import 'package:analyzer/dart/element/element.dart';

import 'meta_middleware.dart';
import 'meta_param.dart';
import 'meta_return_type.dart';

class MetaMethod {
  const MetaMethod({
    required this.name,
    required this.method,
    required this.path,
    required this.annotations,
    required this.params,
    required this.middlewares,
    required this.returnType,
  });

  final String name;
  final String method;
  final String? path;
  final Iterable<ElementAnnotation> annotations;
  final Iterable<MetaParam> params;
  final Iterable<MetaMiddleware> middlewares;
  final MetaReturnType returnType;
}
