import 'package:file/local.dart';
import 'package:zora_gen/parse_routes.dart';
import 'package:zora_gen_core/zora_gen_core.dart';

Future<List<MetaRoute>> parseRoutes(String path) async {
  final fs = LocalFileSystem();

  if (!fs.directory(path).existsSync()) {
    throw Exception('Routes directory not found');
  }

  // check if path ends with routes
  if (!path.endsWith('routes')) {
    throw Exception('Path must point to routes');
  }

  final parser = RouteParser(
    routeDirectory: path,
    fs: fs,
  );

  final routes = await parser.parse();

  return routes;
}
