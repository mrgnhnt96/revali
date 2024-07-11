import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_pipe.dart';
import 'package:revali_server/utils/extract_import.dart';

class ServerBodyAnnotation with ExtractImport {
  ServerBodyAnnotation({
    required this.access,
    required this.pipe,
    required this.acceptsNull,
  });

  factory ServerBodyAnnotation.fromElement(
    DartObject object,
    ElementAnnotation annotation,
  ) {
    final access = object.getField('access')?.toListValue()?.map((e) {
      return e.toStringValue()!;
    }).toList();

    final pipe = object.getField('pipe')?.toTypeValue();

    final pipeSuper =
        (pipe?.element as ClassElement?)?.allSupertypes.firstWhere((element) {
      return element.element.name == 'Pipe';
    });

    final firstTypeArg = pipeSuper?.typeArguments.first;

    return ServerBodyAnnotation(
      access: access,
      pipe: pipe == null ? null : ServerPipe.fromType(pipe),
      acceptsNull: firstTypeArg == null
          ? null
          : firstTypeArg.nullabilitySuffix == NullabilitySuffix.question,
    );
  }

  final List<String>? access;
  final ServerPipe? pipe;
  final bool? acceptsNull;

  @override
  List<ExtractImport?> get extractors => [pipe];

  @override
  List<ServerImports?> get imports => const [];
}
