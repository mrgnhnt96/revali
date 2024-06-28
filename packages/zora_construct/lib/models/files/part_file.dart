import 'package:zora_construct/models/files/dart_file.dart';

class PartFile {
  const PartFile({
    required this.basename,
    required this.content,
  });

  final String basename;
  final String content;

  String getContent(DartFile parent) {
    if (content.contains(RegExp("^import '"))) {
      throw Exception('Part files cannot contain import statements.');
    }

    return '''
part of '${parent.basename}';
$content''';
  }
}
