import 'dart:core';

import 'package:revali_construct/models/meta_param.dart';
import 'package:revali_construct/models/meta_return_type.dart';
import 'package:revali_construct/models/meta_web_socket_method.dart';
import 'package:revali_construct/types/annotation_getter.dart';

class MetaMethod {
  const MetaMethod({
    required this.name,
    required this.method,
    required this.path,
    required this.params,
    required this.returnType,
    required this.annotationsMapper,
    required this.webSocketMethod,
  });

  final String name;
  final String method;
  final String? path;
  final Iterable<MetaParam> params;
  final MetaReturnType returnType;
  final AnnotationMapper annotationsMapper;
  final MetaWebSocketMethod? webSocketMethod;

  bool get isWebSocket => webSocketMethod != null;
}
