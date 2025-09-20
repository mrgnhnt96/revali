import 'package:revali_construct/models/files/any_file.dart';

class RevaliDirectory {
  RevaliDirectory({required List<AnyFile> files})
    : assert(files.isNotEmpty, 'Directory must contain at least one file.') {
    final allFiles = <AnyFile>[...files];

    for (final file in files) {
      allFiles.addAll(file.subFiles);
    }

    this.files = allFiles;
  }

  late final List<AnyFile> files;
}
