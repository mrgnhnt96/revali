import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:revali_router_core/revali_router_core.dart';
import 'package:revali_server/converters/base_parameter_annotation.dart';
import 'package:revali_server/converters/has_pipe.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_pipe.dart';
import 'package:revali_server/utils/extract_import.dart';

class ServerQueryAnnotation
    with ExtractImport
    implements HasPipe, BaseParameterAnnotation {
  ServerQueryAnnotation({
    required this.name,
    required this.pipe,
    required this.all,
  });

  factory ServerQueryAnnotation.fromElement(
    DartObject object,
    // ignore: avoid_unused_constructor_parameters
    ElementAnnotation annotation,
  ) {
    final name = object.getField('name')?.toStringValue();
    final pipe = object.getField('pipe')?.toTypeValue();
    final all = object.getField('all')?.toBoolValue();

    return ServerQueryAnnotation(
      all: all ?? false,
      name: name,
      pipe: ServerPipe.fromType(pipe),
    );
  }

  @override
  final String? name;
  @override
  final ServerPipe? pipe;
  final bool all;

  @override
  AnnotationType get type => switch (all) {
        true => AnnotationType.queryAll,
        false => AnnotationType.query,
      };

  @override
  List<ExtractImport?> get extractors => [pipe];

  @override
  List<ServerImports?> get imports => const [];
}
