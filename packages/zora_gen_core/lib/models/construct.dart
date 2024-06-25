import 'meta_route.dart';

abstract interface class Construct {
  const Construct();

  Map<String, String> generate(List<MetaRoute> routes);
}
