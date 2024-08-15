import 'package:revali_construct/models/files/any_file.dart';
import 'package:revali_construct/revali_construct.dart';

class RevaliBuildConstruct extends BuildConstruct {
  const RevaliBuildConstruct();

  @override
  BuildDirectory generate(RevaliContext context, MetaServer server) {
    return BuildDirectory(
      files: [
        const AnyFile(basename: 'Dockerfile', content: '# Dockerfile'),
      ],
    );
  }
}
