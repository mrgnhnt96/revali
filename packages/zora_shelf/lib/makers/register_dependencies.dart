import 'package:code_builder/code_builder.dart';
import 'package:zora_construct/models/files/part_file.dart';

PartFile registerDependencies(String Function(Spec) formatter) {
  final method = Method(
    (b) => b
      ..name = '_registerDependencies'
      ..returns = refer('void')
      ..body = Block.of([
        refer('DI')
            .property('instance')
            .property(
              'registerLazySingleton',
            )
            .call(
          [
            refer('Repo').property('new'),
          ],
        ).statement,
        refer('DI')
            .property('instance')
            .property('registerLazySingleton')
            .call([
          refer('Logger').property('new'),
        ]).statement,
      ]),
  );

  final content = formatter(method);

  return PartFile(
    path: ['server', '__register_dependencies.dart'],
    content: content,
  );
}
