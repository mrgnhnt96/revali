import 'package:revali_server/converters/server_imports.dart';
import 'package:revali_server/converters/server_mimic.dart';
import 'package:revali_server/converters/server_type_reference.dart';
import 'package:revali_server/utils/extract_import.dart';

class ServerAppObservers with ExtractImport {
  ServerAppObservers();

  List<ServerMimic> mimics = [];
  List<ServerTypeReference> types = [];

  bool get hasObservers => types.isNotEmpty || mimics.isNotEmpty;

  @override
  List<ExtractImport?> get extractors => [...types, ...mimics];

  @override
  List<ServerImports?> get imports => [];
}
