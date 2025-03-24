import 'package:revali_construct/revali_construct.dart';
import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_type.dart';
import 'package:revali_server/utils/extract_import.dart';

class ServerRecordProp with ExtractImport {
  ServerRecordProp({
    required this.name,
    required this.isNamed,
    required this.type,
  });

  factory ServerRecordProp.fromMeta(MetaRecordProp prop) {
    return ServerRecordProp(
      name: prop.name,
      isNamed: prop.isNamed,
      type: ServerType.fromMeta(prop.type),
    );
  }

  final String? name;
  final bool isNamed;
  final ServerType type;

  bool get isPositioned => !isNamed;

  @override
  List<ExtractImport?> get extractors => [type];

  @override
  List<ServerImports?> get imports => [];
}
