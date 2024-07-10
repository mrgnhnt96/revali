import 'package:revali_construct/revali_construct.dart';

class MetaServer {
  const MetaServer({
    required this.apps,
    required this.routes,
  });

  final List<MetaRoute> routes;
  final List<MetaAppConfig> apps;
}
