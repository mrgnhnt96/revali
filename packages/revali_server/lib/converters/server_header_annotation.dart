import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:collection/collection.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_pipe.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';
import 'package:revali_server/utils/extract_import.dart';

class ServerHeaderAnnotation with ExtractImport {
  ServerHeaderAnnotation({
    required this.name,
    required this.pipe,
    required this.acceptsNull,
    required this.all,
  });

  factory ServerHeaderAnnotation.fromElement(
    DartObject object,
    // ignore: avoid_unused_constructor_parameters
    ElementAnnotation annotation,
  ) {
    final name = object.getField('name')?.toStringValue();
    final pipe = object.getField('pipe')?.toTypeValue();

    final pipeSuper = (pipe?.element as ClassElement?)
        ?.allSupertypes
        .firstWhereOrNull((element) {
      // ignore: unnecessary_parenthesis
      return element.element.name == (Pipe).name;
    });

    final firstTypeArg = pipeSuper?.typeArguments.first;

    return ServerHeaderAnnotation(
      name: name,
      pipe: pipe != null ? ServerPipe.fromType(pipe) : null,
      all: object.getField('all')?.toBoolValue() ?? false,
      acceptsNull: firstTypeArg == null
          ? null
          : firstTypeArg.nullabilitySuffix == NullabilitySuffix.question,
    );
  }

  final String? name;
  final ServerPipe? pipe;
  final bool? acceptsNull;
  final bool all;

  @override
  List<ExtractImport?> get extractors => [pipe];

  @override
  List<ServerImports?> get imports => const [];
}
