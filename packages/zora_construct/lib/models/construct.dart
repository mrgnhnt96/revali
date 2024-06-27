import 'meta_route.dart';

abstract class Construct<T> {
  const Construct();

  T generate(List<MetaRoute> routes);
}
