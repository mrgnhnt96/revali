import 'package:revali_construct/models/files/any_file.dart';

class RevaliDirectory<T extends AnyFile> {
  const RevaliDirectory({
    required this.name,
    required this.files,
  }) : assert(files.length != 0, 'Directory must contain at least one file.');

  final String name;

  final List<T> files;
}
