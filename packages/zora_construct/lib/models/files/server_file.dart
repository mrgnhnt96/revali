import 'package:zora_construct/models/files/dart_file.dart';

class ServerFile extends DartFile {
  const ServerFile({
    required super.content,
    super.parts = const [],
  }) : super(basename: fileName);

  static const String fileName = 'server.dart';
}
