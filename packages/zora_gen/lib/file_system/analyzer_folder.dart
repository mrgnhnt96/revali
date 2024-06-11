import 'dart:io' as io;

import 'package:analyzer/file_system/file_system.dart';
import 'package:file/file.dart' show FileSystem, FileSystemEvent;
import 'package:path/path.dart' as p;
import 'package:watcher/src/watch_event.dart';
import 'package:zora_gen/file_system/analyzer_file.dart';
import 'package:zora_gen/file_system/file_resource_provider.dart';
import 'package:zora_gen/file_system/util/watch_event_extension.dart';

class AnalyzerFolder implements Folder {
  AnalyzerFolder(this.fileSystem, this.directory, this.provider);

  final io.Directory directory;

  final FileSystem fileSystem;

  @override
  String canonicalizePath(String path) {
    return p.canonicalize(path);
  }

  @override
  Stream<WatchEvent> get changes {
    return directory.watch(events: FileSystemEvent.all).toAnalyzerStream();
  }

  @override
  bool contains(String path) {
    return p.isWithin(directory.path, path);
  }

  @override
  Folder copyTo(Folder parentFolder) {
    final files = directory.listSync(recursive: true);
    final newPath = p.join(parentFolder.path, p.basename(path));
    final newFolder = fileSystem.directory(newPath);

    for (final file in files) {
      if (file is! io.File) {
        continue;
      }

      final newPath = p.join(newFolder.path, p.basename(file.path));
      file.copySync(newPath);
    }

    return AnalyzerFolder(fileSystem, newFolder, provider);
  }

  @override
  Resource getChild(String relPath) {
    final path = p.join(directory.path, relPath);
    final child = fileSystem.file(path);

    if (child.existsSync()) {
      return child.toAnalyzerFile();
    }

    return fileSystem.directory(path).toAnalyzerFolder(fileSystem);
  }

  @override
  File getChildAssumingFile(String relPath) {
    final path = p.join(directory.path, relPath);
    final child = fileSystem.file(path);

    return child.toAnalyzerFile();
  }

  @override
  Folder getChildAssumingFolder(String relPath) {
    final path = p.join(directory.path, relPath);
    final child = fileSystem.directory(path);

    return child.toAnalyzerFolder(fileSystem);
  }

  @override
  List<Resource> getChildren() {
    Iterable<Resource> children() sync* {
      for (final entity in directory.listSync()) {
        if (entity is io.File) {
          yield entity.toAnalyzerFile(fileSystem);
        } else if (entity is io.Directory) {
          yield entity.toAnalyzerFolder(fileSystem);
        }
      }
    }

    return children().toList();
  }

  @override
  bool isOrContains(String path) {
    return p.isWithin(directory.path, path);
  }

  @override
  bool get isRoot => directory.path == '/';

  @override
  Folder get parent2 => directory.parent.toAnalyzerFolder(fileSystem);

  @override
  final ResourceProvider provider;

  @override
  String get shortName => p.basename(directory.path);

  @override
  Uri toUri() {
    return Uri.file(directory.path);
  }

  @override
  void create() {
    directory.createSync(recursive: true);
  }

  @override
  void delete() => directory.deleteSync(recursive: true);

  @override
  bool get exists => directory.existsSync();

  @override
  Folder get parent => directory.parent.toAnalyzerFolder(fileSystem);

  @override
  String get path => directory.path;

  @override
  Resource resolveSymbolicLinksSync() {
    final resolved = directory.resolveSymbolicLinksSync();

    return fileSystem.directory(resolved).toAnalyzerFolder(fileSystem);
  }

  @override
  ResourceWatcher watch() {
    final watcher = directory
        .watch(events: FileSystemEvent.all, recursive: true)
        .toAnalyzerStream();

    return ResourceWatcher(watcher, () async {});
  }
}

extension DirectoryIOX on io.Directory {
  AnalyzerFolder toAnalyzerFolder(FileSystem fs) => AnalyzerFolder(
        fs,
        fs.directory(path),
        FileResourceProvider(fs),
      );
}
