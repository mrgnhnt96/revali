import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:revali_router_core/revali_router_core.dart';
import 'package:revali_server/converters/base_parameter_annotation.dart';
import 'package:revali_server/converters/has_pipe.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_pipe.dart';
import 'package:revali_server/utils/extract_import.dart';

class ServerCookieAnnotation
    with ExtractImport
    implements HasPipe, BaseParameterAnnotation {
  ServerCookieAnnotation({required this.name, required this.pipe});

  factory ServerCookieAnnotation.fromElement(
    DartObject object,
    // ignore: avoid_unused_constructor_parameters
    ElementAnnotation annotation,
  ) {
    final name = object.getField('name')?.toStringValue();
    final pipe = object.getField('pipe')?.toTypeValue();

    return ServerCookieAnnotation(name: name, pipe: ServerPipe.fromType(pipe));
  }

  @override
  final String? name;
  @override
  final ServerPipe? pipe;

  @override
  AnnotationType get type => AnnotationType.cookie;

  @override
  List<ExtractImport?> get extractors => [pipe];

  @override
  List<ServerImports?> get imports => const [];
}
