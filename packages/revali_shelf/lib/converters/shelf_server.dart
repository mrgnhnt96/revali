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
    final imports = <String>{};

    for (final route in routes) {
      imports.add(route.importPath);
    }

    for (final imprt in imports) {
      if (imprt.startsWith('file:')) {
        yield imprt.replaceFirst('file:', '');
      } else {
        yield imprt;
      }
    }
  }
}
