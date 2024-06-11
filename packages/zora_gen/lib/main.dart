import 'package:file/local.dart';
import 'package:path/path.dart' as path;
import 'package:zora_gen/parse_routes.dart';

void main() async {
  final fs = LocalFileSystem();

  final root = fs.currentDirectory.parent.parent.path;
  final routesPath = path.join(root, 'examples', 'routes');

  if (!fs.directory(routesPath).existsSync()) {
    throw Exception('Routes directory not found');
  }

  final parser = RouteParser(
    routeDirectory: routesPath,
    fs: fs,
  );

  final routes = await parser.parse();

  print(routes);
}
