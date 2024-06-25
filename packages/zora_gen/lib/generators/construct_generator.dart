import 'package:zora_gen/zora_gen.dart';
import 'package:zora_gen_core/zora_gen_core.dart';

class ConstructGenerator {
  const ConstructGenerator({
    required this.path,
    required this.constructs,
  });

  final String path;
  final List<Construct> constructs;

  Future<void> generate() async {
    final routes = await parseRoutes(path);
    for (final construct in constructs) {
      final result = construct.generate(routes);

      print(result);
    }
  }
}
