import 'package:zora_gen_core/zora_gen_core.dart';

class ZoraShelfConstruct implements Construct {
  const ZoraShelfConstruct();

  @override
  Map<String, String> generate(List<MetaRoute> routes) {
    return {'file.dart': 'content'};
  }
}
