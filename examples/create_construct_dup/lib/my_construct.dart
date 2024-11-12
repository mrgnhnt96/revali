import 'package:revali_construct/revali_construct.dart';

Construct myConstruct([ConstructOptions? options]) {
  return const MyConstruct();
}

class MyConstruct extends Construct {
  const MyConstruct();

  @override
  RevaliDirectory<AnyFile> generate(
    covariant RevaliContext context,
    MetaServer server,
  ) {
    return RevaliDirectory(
      files: [
        const AnyFile(basename: 'text', content: 'dup', extension: 'txt'),
        const AnyFile(basename: 'dup', content: 'dup', extension: 'txt'),
      ],
    );
  }
}
