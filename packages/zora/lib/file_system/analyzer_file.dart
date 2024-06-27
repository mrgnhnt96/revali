import 'dart:io' as io;
import 'dart:typed_data';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/source/source_resource.dart';
import 'package:file/file.dart' as f;
import 'package:file/file.dart' show FileSystem, FileSystemEvent;
import 'package:path/path.dart' as p;
import 'package:watcher/src/watch_event.dart';
import 'package:zora/file_system/analyzer_folder.dart';
import 'package:zora/file_system/file_resource_provider.dart';
import 'package:zora/file_system/util/watch_event_extension.dart';

class AnalyzerFile implements File {
  AnalyzerFile(
    this.file,
    this.provider,
  );

  @override
  final ResourceProvider provider;
  final f.File file;

  FileSystem get fileSystem => file.fileSystem;

  @override
  Stream<WatchEvent> get changes {
    return file.watch(events: FileSystemEvent.all).toAnalyzerStream();
  }

  @override
  File copyTo(Folder parentFolder) {
    final newPath = p.join(parentFolder.path, p.basename(path));
    final newFile = fileSystem.file(newPath);

    file.copySync(newPath);

    return AnalyzerFile(newFile, provider);
  }

  @override
  Source createSource([Uri? uri]) {
    return FileSource(this, uri ?? p.context.toUri(path));
  }

  @override
  bool isOrContains(String path) {
    return p.isWithin(file.path, path);
  }

  @override
  int get modificationStamp => file.statSync().modified.millisecondsSinceEpoch;

  @override
  Folder get parent2 => file.parent.toAnalyzerFolder(fileSystem);

  @override
  String get shortName => p.basename(file.path);

  @override
  Uri toUri() => Uri.file(file.path);

  @override
  void delete() {
    file.deleteSync();
  }

  @override
  bool get exists => file.existsSync();

  @override
  int get lengthSync => file.statSync().size;

  @override
  Folder get parent => file.parent.toAnalyzerFolder(fileSystem);

  @override
  String get path => file.path;

  @override
  Uint8List readAsBytesSync() {
    return file.readAsBytesSync();
  }

  @override
  String readAsStringSync() {
    return file.readAsStringSync();
  }

  @override
  File renameSync(String newPath) {
    final newFile = fileSystem.file(newPath);

    file.renameSync(newPath);

    return AnalyzerFile(newFile, provider);
  }

  @override
  Resource resolveSymbolicLinksSync() {
    final resolved = file.resolveSymbolicLinksSync();

    return fileSystem.file(resolved).toAnalyzerFile();
  }

  @override
  ResourceWatcher watch() {
    final watcher = file.watch(events: FileSystemEvent.all).toAnalyzerStream();

    return ResourceWatcher(watcher, () async {});
  }

  @override
  void writeAsBytesSync(List<int> bytes) {
    file.writeAsBytesSync(bytes);
  }

  @override
  void writeAsStringSync(String content) {
    file.writeAsStringSync(content);
  }
}

extension FileX on f.File {
  AnalyzerFile toAnalyzerFile() => AnalyzerFile(
        this,
        FileResourceProvider(fileSystem),
      );
}

extension FileIOX on io.File {
  AnalyzerFile toAnalyzerFile(FileSystem fs) => AnalyzerFile(
        fs.file(path),
        FileResourceProvider(fs),
      );
}
