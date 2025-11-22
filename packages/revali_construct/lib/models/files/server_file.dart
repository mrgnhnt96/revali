import 'package:revali_construct/models/files/dart_file.dart';

final class ServerFile extends DartFile {
  ServerFile({required super.content, super.parts = const []})
    : super(basename: name);

  static const String name = 'server';
  static const String nameWithExtension = 'server.dart';
}
