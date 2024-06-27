import 'dart:io' as io;

import 'package:analyzer/file_system/file_system.dart';
import 'package:file/file.dart' show FileSystem;
import 'package:path/path.dart' as p;
import 'package:zora/file_system/analyzer_file.dart';
import 'package:zora/file_system/analyzer_folder.dart';

class FileResourceProvider extends ResourceProvider {
  FileResourceProvider(this.fs);

  final FileSystem fs;

  @override
  File getFile(String path) {
    final file = fs.file(path);

    return file.toAnalyzerFile();
  }

  @override
  Folder getFolder(String path) {
    final folder = fs.directory(path);

    return folder.toAnalyzerFolder(fs);
  }

  @override
  Resource getResource(String path) {
    final file = fs.file(path);

    if (file.existsSync()) {
      return file.toAnalyzerFile();
    }

    final directory = fs.directory(path);

    return directory.toAnalyzerFolder(fs);
  }

  @override
  Folder? getStateLocation(String pluginId) {
    final path = p.join(io.Directory.systemTemp.path, pluginId);

    return fs.directory(path).toAnalyzerFolder(fs);
  }

  @override
  p.Context get pathContext => p.context;
}
