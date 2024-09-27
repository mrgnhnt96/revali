import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:collection/collection.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_pipe.dart';
import 'package:revali_server/makers/utils/type_extensions.dart';
import 'package:revali_server/utils/extract_import.dart';

class ServerQueryAnnotation with ExtractImport {
  ServerQueryAnnotation({
    required this.name,
    required this.pipe,
    required this.acceptsNull,
    required this.all,
  });

  factory ServerQueryAnnotation.fromElement(
    DartObject object,
    // ignore: avoid_unused_constructor_parameters
    ElementAnnotation annotation,
  ) {
    final name = object.getField('name')?.toStringValue();
    final pipe = object.getField('pipe')?.toTypeValue();
    final all = object.getField('all')?.toBoolValue() ?? false;

    final pipeSuper = (pipe?.element as ClassElement?)
        ?.allSupertypes
        .firstWhereOrNull((element) {
      // ignore: unnecessary_parenthesis
      return element.element.name == (Pipe).name;
    });

    final firstTypeArg = pipeSuper?.typeArguments.first;

    return ServerQueryAnnotation(
      all: all,
      name: name,
      pipe: switch (pipe) {
        final pipe? => ServerPipe.fromType(pipe),
        _ => null,
      },
      acceptsNull: switch (firstTypeArg?.nullabilitySuffix) {
        final prefix? => prefix == NullabilitySuffix.question,
        _ => null,
      },
    );
  }

  final String? name;
  final ServerPipe? pipe;
  final bool all;
  final bool? acceptsNull;

  @override
  List<ExtractImport?> get extractors => [pipe];

  @override
  List<ServerImports?> get imports => const [];
}
