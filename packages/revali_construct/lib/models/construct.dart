import 'package:revali_construct/models/files/revali_directory.dart';
import 'package:revali_construct/models/meta_server.dart';
import 'package:revali_construct/models/revali_context.dart';

abstract class Construct<T extends RevaliDirectory> {
  const Construct();

  T generate(covariant RevaliContext context, MetaServer server);
}
