import 'package:zora_gen/parse_routes.dart';
import 'package:zora_gen_core/zora_gen_core.dart';
import 'package:file/file.dart';

class RoutesHandler {
  const RoutesHandler({
    required this.fs,
  });

  final FileSystem fs;

  Future<List<MetaRoute>> parse(String path) async {
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
}
