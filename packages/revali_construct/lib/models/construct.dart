import 'package:revali_construct/models/files/dart_file.dart';
import 'package:revali_construct/models/meta_server.dart';
import 'package:revali_construct/models/revali_context.dart';

abstract class Construct<T extends DartFile> {
  const Construct();

  T generate(RevaliContext context, MetaServer server);
}
