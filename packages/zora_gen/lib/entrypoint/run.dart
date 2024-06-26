import 'package:file/local.dart';
import 'package:zora_gen/construct_runner/construct_runner.dart';
import 'package:zora_gen_core/zora_gen_core.dart';

Future<int> run(
  List<String> args, {
  required List<ConstructMaker> constructs,
  required String path,
}) async {
  final fs = LocalFileSystem();

  final runner = ConstructRunner(
    fs: fs,
    constructs: constructs,
    rootPath: path,
  );

  final result = await runner.run(args);

  return result;
}
