import 'package:zora_construct/models/files/dart_file.dart';
import 'package:zora_construct/models/meta_server.dart';

abstract class Construct<T extends DartFile> {
  const Construct();

  T generate(MetaServer server);
}
