// ignore_for_file: unnecessary_parenthesis

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:collection/collection.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_server/converters/server_bind.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';
import 'package:revali_server/utils/extract_import.dart';

class ServerBindsAnnotation with ExtractImport {
  ServerBindsAnnotation({
    required this.bind,
    required this.acceptsNull,
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

    final firstTypeArg = bindSuper?.typeArguments.first;

    return ServerBindsAnnotation(
      bind: ServerBind.fromType(bind),
      acceptsNull: switch (firstTypeArg?.nullabilitySuffix) {
        final prefix? => prefix == NullabilitySuffix.question,
        _ => null,
      },
    );
  }

  final ServerBind bind;
  final bool? acceptsNull;

  @override
  List<ExtractImport?> get extractors => [bind];

  @override
  List<ServerImports?> get imports => const [];
}
