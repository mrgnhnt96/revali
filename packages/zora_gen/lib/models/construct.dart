import 'package:zora_gen/models/meta_route.dart';
import 'package:zora_gen/zora_gen.dart';

abstract interface class Construct {
  const Construct();

  Map<String, String> generate(List<MetaRoute> routes);
}
