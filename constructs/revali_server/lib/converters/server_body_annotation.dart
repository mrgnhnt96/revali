import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:revali_router_core/revali_router_core.dart';
import 'package:revali_server/converters/base_parameter_annotation.dart';
import 'package:revali_server/converters/has_pipe.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_pipe.dart';
import 'package:revali_server/utils/extract_import.dart';

class ServerBodyAnnotation
    with ExtractImport
    implements HasPipe, BaseParameterAnnotation {
  ServerBodyAnnotation({required this.access, required this.pipe});

  factory ServerBodyAnnotation.fromElement(
    DartObject object,
    // ignore: avoid_unused_constructor_parameters
    ElementAnnotation annotation,
  ) {
    final access = object.getField('access')?.toListValue()?.map((e) {
      return e.toStringValue()!;
    }).toList();

    final pipe = object.getField('pipe')?.toTypeValue();

    return ServerBodyAnnotation(
      access: access,
      pipe: ServerPipe.fromType(pipe),
    );
  }

  final List<String>? access;
  @override
  final ServerPipe? pipe;

  @override
  String? get name => null;

  @override
  AnnotationType get type => AnnotationType.body;

  @override
  List<ExtractImport?> get extractors => [pipe];

  @override
  List<ServerImports?> get imports => const [];
}
