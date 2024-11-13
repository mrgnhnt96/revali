import 'package:revali_construct/models/construct.dart';
import 'package:revali_construct/models/files/build_directory.dart';
import 'package:revali_construct/models/meta_server.dart';
import 'package:revali_construct/models/revali_build_context.dart';

abstract base class BuildConstruct implements Construct<BuildDirectory> {
  const BuildConstruct();

  Future<void> preBuild(RevaliBuildContext context, MetaServer server) async {}

  @override
  BuildDirectory generate(RevaliBuildContext context, MetaServer server);

  Future<void> postBuild(RevaliBuildContext context, MetaServer server) async {}
}
