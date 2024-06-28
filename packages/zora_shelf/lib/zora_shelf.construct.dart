import 'package:zora_construct/models/files/server_file.dart';
import 'package:zora_construct/zora_construct.dart';

class ZoraShelfConstruct implements ServerConstruct {
  const ZoraShelfConstruct();

  @override
  ServerFile generate(List<MetaRoute> routes) {
    return ServerFile(
      content: '',
    );
  }
}
