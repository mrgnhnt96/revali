import 'package:zora_gen/zora_gen.dart';

class ZoraShelfConstruct implements Construct {
  const ZoraShelfConstruct();

  @override
  Map<String, String> generate(List<MetaRoute> routes) {
    return {'file.dart': 'content'};
  }
}
