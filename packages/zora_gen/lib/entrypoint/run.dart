import 'package:zora_gen/generate.dart';
import 'package:zora_gen/models/construct.dart';

Future<int> run(
  List<String> args, {
  required List<Construct> constructs,
  required String path,
}) async {
  final routes = await parseRoutes(path);

  for (final construct in constructs) {
    final result = construct.generate(routes);

    print(result);
  }

  return 0;
}
