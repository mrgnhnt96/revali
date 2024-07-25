import 'dart:io' as io;

import 'package:file/file.dart' show FileSystemEvent;
// ignore: implementation_imports
import 'package:watcher/src/watch_event.dart';

extension StreamFileSystemX on Stream<FileSystemEvent> {
  Stream<WatchEvent> toAnalyzerStream() async* {
    await for (final event in this) {
      final type = switch (event.type) {
        io.FileSystemEvent.create => ChangeType.ADD,
        io.FileSystemEvent.modify => ChangeType.MODIFY,
        io.FileSystemEvent.delete => ChangeType.REMOVE,
        io.FileSystemEvent.move => ChangeType.MODIFY,
        _ => throw UnimplementedError(),
      };
      yield WatchEvent(type, event.path);
    }
  }
}
