import 'package:revali_construct/models/files/dart_file.dart';

final class ServerFile extends DartFile {
  ServerFile({
    required super.content,
    super.parts = const [],
  }) : super(basename: fileName);

  static const String fileName = 'server.dart';
}
