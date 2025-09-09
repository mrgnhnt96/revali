// ignore_for_file: unnecessary_parenthesis

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_router_core/types/annotation_type.dart';
import 'package:revali_server/converters/base_parameter_annotation.dart';
import 'package:revali_server/converters/server_bind.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_type.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';
import 'package:revali_server/utils/extract_import.dart';

class ServerBindsAnnotation
    with ExtractImport
    implements BaseParameterAnnotation {
  ServerBindsAnnotation({
    required this.bind,
    required this.convertsTo,
  });

  factory ServerBindsAnnotation.fromElement(
    DartObject object,
    // ignore: avoid_unused_constructor_parameters
    ElementAnnotation annotation,
  ) {
    final bind = object.getField('bind')?.toTypeValue();
    if (bind == null) {
      throw ArgumentError('Invalid type');
    }

    final bindSuper = (bind.element as ClassElement?)
        ?.allSupertypes
        .firstWhereOrNull((element) {
      return element.element.name == (Bind).name;
    });

    if (bindSuper == null) {
      throw ArgumentError('Failed to find superclass of $bind');
    }

    final [typeArg] = bindSuper.typeArguments;

    return ServerBindsAnnotation(
      bind: ServerBind.fromType(bind),
      convertsTo: ServerType.fromType(typeArg),
    );
  }

  final ServerBind bind;
  final ServerType convertsTo;

  @override
  List<ExtractImport?> get extractors => [bind, convertsTo];

  @override
  List<ServerImports?> get imports => const [];

  @override
  String? get name => null;

  @override
  AnnotationType get type => AnnotationType.binds;
}
