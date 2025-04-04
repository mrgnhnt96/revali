import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:revali_router_core/pipe/annotation_type.dart';
import 'package:revali_server/converters/base_parameter_annotation.dart';
import 'package:revali_server/converters/has_pipe.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_pipe.dart';
import 'package:revali_server/utils/extract_import.dart';

class ServerParamAnnotation
    with ExtractImport
    implements HasPipe, BaseParameterAnnotation {
  ServerParamAnnotation({
    required this.name,
    required this.pipe,
  });

  factory ServerParamAnnotation.fromElement(
    DartObject object,
    // ignore: avoid_unused_constructor_parameters
    ElementAnnotation annotation,
  ) {
    final name = object.getField('name')?.toStringValue();
    final pipe = object.getField('pipe')?.toTypeValue();

    return ServerParamAnnotation(
      name: name,
      pipe: ServerPipe.fromType(pipe),
    );
  }

  @override
  final String? name;
  @override
  final ServerPipe? pipe;

  @override
  AnnotationType get type => AnnotationType.param;

  @override
  List<ExtractImport?> get extractors => [pipe];

  @override
  List<ServerImports?> get imports => const [];
}
