import 'package:zora_construct/models/files/part_file.dart';
import 'package:zora_construct/models/files/server_file.dart';
import 'package:zora_construct/zora_construct.dart';

class ZoraShelfConstruct implements ServerConstruct {
  const ZoraShelfConstruct();

  @override
  ServerFile generate(List<MetaRoute> routes) {
    return ServerFile(
      content: '// This is other',
      parts: [
        PartFile(
          basename: '__other.dart',
          content: "import '';// sup dude",
        ),
      ],
    );
  }
}
