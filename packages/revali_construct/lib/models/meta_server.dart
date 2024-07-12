import 'package:revali_construct/models/meta_app_config.dart';
import 'package:revali_construct/models/meta_public.dart';
import 'package:revali_construct/models/meta_route.dart';

class MetaServer {
  const MetaServer({
    required this.apps,
    required this.public,
    required this.routes,
  });

  final List<MetaRoute> routes;
  final List<MetaPublic> public;
  final List<MetaAppConfig> apps;
}
