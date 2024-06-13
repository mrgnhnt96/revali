import 'package:zora_core/models/route.dart';

abstract interface class Construct {
  const Construct();

  Map<String, String> generate(List<Route> routes);
}
