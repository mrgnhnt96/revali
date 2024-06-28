import 'package:zora_construct/models/files/dart_file.dart';

class PartFile {
  const PartFile({
    required this.basename,
    required this.content,
  });

  final String basename;
  final String content;

  String getContent(DartFile parent) {
    return '''
part of '${parent.basename}';
$content''';
  }
}
