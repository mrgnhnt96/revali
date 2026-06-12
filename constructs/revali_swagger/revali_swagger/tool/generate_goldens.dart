import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_swagger/models/swagger_settings.dart';
import 'package:revali_swagger/src/swagger_construct.dart';

import '../test/helpers/swagger_e2e_helper.dart';

void main() async {
  final helper = await SwaggerE2eHelper.create();

  final goldenDir = p.normalize(
    p.join(Directory.current.path, 'test', 'fixtures', 'golden'),
  );
  Directory(goldenDir).createSync(recursive: true);

  const context = RevaliContext(flavor: null, mode: Mode.debug);
  final settings = SwaggerSettings.fromJson({
    'title': 'Sample API',
    'version': '1.0.0',
  });
  final result = SwaggerConstruct(settings).generate(context, helper.server);

  for (final file in result.files) {
    final outPath = p.join(goldenDir, '${file.basename}.${file.extension}');
    File(outPath).writeAsStringSync(file.content);
    // ignore: avoid_print
    print('Written: $outPath');
  }
}
