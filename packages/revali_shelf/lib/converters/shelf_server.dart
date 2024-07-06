import 'package:revali_construct/revali_construct.dart';
import 'package:revali_shelf/converters/shelf_parent_route.dart';

class ShelfServer {
  const ShelfServer({
    required this.routes,
  });

  factory ShelfServer.fromMeta(MetaServer server) {
    return ShelfServer(
      routes: server.routes.map((e) => ShelfParentRoute.fromMeta(e)).toList(),
    );
  }

  final List<ShelfParentRoute> routes;

  Iterable<String> get imports sync* {
    for (final route in routes) {
      yield* route.importPath.imports;
    }
  }
}
