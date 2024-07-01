import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/models/files/part_file.dart';

PartFile registerControllers(String Function(Spec) formatter) {
  final method = Method(
    (b) => b
      ..name = '_registerControllers'
      ..returns = refer('void')
      ..body = Block.of([
        refer('DI').property('instance').property('registerLazySingleton').call(
          [
            refer('() => ThisController(DI.instance.get(), DI.instance.get())'),
          ],
          {},
          [
            refer('ThisController'),
          ],
        ).statement,
      ]),
  );

  final content = formatter(method);

  return PartFile(
    path: ['server', '__register_controllers.dart'],
    content: content,
  );
}
