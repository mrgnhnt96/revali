import 'package:revali_construct/revali_construct.dart';

class ServerPublic {
  const ServerPublic({
    required this.path,
  });

  factory ServerPublic.fromMeta(MetaPublic meta) {
    return ServerPublic(
      path: meta.path,
    );
  }

  final String path;
}
