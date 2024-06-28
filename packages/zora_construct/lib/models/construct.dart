import 'package:zora_construct/models/files/dart_file.dart';

import 'meta_route.dart';

abstract class Construct<T extends DartFile> {
  const Construct();

  T generate(List<MetaRoute> routes);
}
