import 'package:revali_construct/revali_construct.dart';

Construct myConstruct([ConstructOptions? options]) {
  return const MyConstruct();
}

class MyConstruct extends Construct {
  const MyConstruct();

  @override
  RevaliDirectory generate(
    covariant RevaliContext context,
    MetaServer server,
  ) {
    return RevaliDirectory(
      files: [
        const AnyFile(
          basename: 'my-text-file',
          extension: 'txt',
          content: 'Hello, World!',
        ),
      ],
    );
  }
}
