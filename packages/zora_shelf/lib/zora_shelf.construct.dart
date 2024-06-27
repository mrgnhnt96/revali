import 'package:zora_gen_core/zora_gen_core.dart';

class ZoraShelfConstruct implements RouterConstruct {
  const ZoraShelfConstruct();

  @override
  String generate(List<MetaRoute> routes) {
    return 'void main() => print(\'Hello, World!\');';
  }
}
