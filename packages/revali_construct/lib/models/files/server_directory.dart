import 'package:revali_construct/models/files/any_file.dart';
import 'package:revali_construct/models/files/revali_directory.dart';
import 'package:revali_construct/models/files/server_file.dart';

class ServerDirectory extends RevaliDirectory {
  ServerDirectory({
    required ServerFile serverFile,
    List<AnyFile> additionalFiles = const [],
  }) : super(files: [serverFile, ...additionalFiles]);
}
