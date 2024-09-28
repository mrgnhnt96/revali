// ignore_for_file: unnecessary_parenthesis

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:collection/collection.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_server/converters/server_custom_param.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';
import 'package:revali_server/utils/extract_import.dart';

class ServerBindsAnnotation with ExtractImport {
  ServerBindsAnnotation({
    required this.customParam,
    required this.acceptsNull,
  });

  factory ServerBindsAnnotation.fromElement(
    DartObject object,
    // ignore: avoid_unused_constructor_parameters
    ElementAnnotation annotation,
  ) {
    final customParam = object.getField('customParam')?.toTypeValue();
    if (customParam == null) {
      throw ArgumentError('Invalid type');
    }

    final customParamSuper = (customParam.element as ClassElement?)
        ?.allSupertypes
        .firstWhereOrNull((element) {
      return element.element.name == (CustomParam).name;
    });

    final firstTypeArg = customParamSuper?.typeArguments.first;

    return ServerBindsAnnotation(
      customParam: ServerCustomParam.fromType(customParam),
      acceptsNull: switch (firstTypeArg?.nullabilitySuffix) {
        final prefix? => prefix == NullabilitySuffix.question,
        _ => null,
      },
    );
  }

  final ServerCustomParam customParam;
  final bool? acceptsNull;

  @override
  List<ExtractImport?> get extractors => [customParam];

  @override
  List<ServerImports?> get imports => const [];
}
