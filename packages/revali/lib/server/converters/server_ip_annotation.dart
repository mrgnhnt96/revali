import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:revali/server/converters/base_parameter_annotation.dart';
import 'package:revali/server/converters/has_pipe.dart';
import 'package:revali/server/converters/server_imports.dart';
import 'package:revali/server/converters/server_pipe.dart';
import 'package:revali/server/utils/extract_import.dart';
import 'package:revali_core/revali_core.dart';

class ServerIpAnnotation
    with ExtractImport
    implements HasPipe, BaseParameterAnnotation {
  ServerIpAnnotation({required this.pipe});

  factory ServerIpAnnotation.fromElement(
    DartObject object,
    // ignore: avoid_unused_constructor_parameters
    ElementAnnotation annotation,
  ) {
    final pipe = object.getField('pipe')?.toTypeValue();

    return ServerIpAnnotation(pipe: ServerPipe.fromType(pipe));
  }

  @override
  final String? name = null;
  @override
  final ServerPipe? pipe;

  @override
  AnnotationType get type => AnnotationType.ip;

  @override
  List<ExtractImport?> get extractors => [pipe];

  @override
  List<ServerImports?> get imports => const [];
}
