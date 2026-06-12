import 'dart:io';

import 'package:revali_construct/revali_construct.dart';
import 'package:revali_swagger/builders/openapi_builder.dart';
import 'package:revali_swagger/builders/schema_registry.dart';
import 'package:revali_swagger/makers/swagger_file.dart';
import 'package:revali_swagger/models/swagger_server.dart';
import 'package:revali_swagger/models/swagger_settings.dart';

class SwaggerConstruct extends Construct {
  const SwaggerConstruct(this.settings);

  final SwaggerSettings settings;

  @override
  RevaliDirectory generate(RevaliContext context, MetaServer server) {
    final registry = SchemaRegistry();
    final swaggerServer = SwaggerServer.fromMeta(
      context,
      server,
      settings,
      registry,
    );
    final spec = buildOpenApiSpec(swaggerServer, registry);
    final files = makeSwaggerFiles(spec);

    for (final warning in registry.warnings) {
      stderr.writeln('[revali_swagger] WARNING: $warning');
    }

    return RevaliDirectory(files: files);
  }
}
