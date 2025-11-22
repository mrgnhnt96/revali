import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:revali_router_core/revali_router_core.dart';
import 'package:revali_server/converters/base_parameter_annotation.dart';
import 'package:revali_server/converters/has_pipe.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_pipe.dart';
import 'package:revali_server/utils/extract_import.dart';

class ServerHeaderAnnotation
    with ExtractImport
    implements HasPipe, BaseParameterAnnotation {
  ServerHeaderAnnotation({
    required this.name,
    required this.pipe,
    required this.all,
  });

  factory ServerHeaderAnnotation.fromElement(
    DartObject object,
    // ignore: avoid_unused_constructor_parameters
    ElementAnnotation annotation,
  ) {
    final name = object.getField('name')?.toStringValue();
    final pipe = object.getField('pipe')?.toTypeValue();
    final all = object.getField('all')?.toBoolValue();

    return ServerHeaderAnnotation(
      name: name,
      pipe: ServerPipe.fromType(pipe),
      all: all ?? false,
    );
  }

  @override
  final String? name;
  @override
  final ServerPipe? pipe;
  final bool all;

  @override
  AnnotationType get type => switch (all) {
    true => AnnotationType.headerAll,
    false => AnnotationType.header,
  };

  @override
  List<ExtractImport?> get extractors => [pipe];

  @override
  List<ServerImports?> get imports => const [];
}
