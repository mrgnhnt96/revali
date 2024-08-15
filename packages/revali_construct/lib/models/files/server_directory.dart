import 'package:revali_construct/models/files/revali_directory.dart';
import 'package:revali_construct/models/files/server_file.dart';

class ServerDirectory extends RevaliDirectory<ServerFile> {
  ServerDirectory({
    required ServerFile serverFile,
  }) : super(
          name: '__SERVER__',
          files: [serverFile],
        );
}
