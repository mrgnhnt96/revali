import 'package:code_builder/code_builder.dart';
import 'package:revali_server/converters/server_generic_type.dart';

List<TypeReference> createGenerics(List<ServerGenericType> generics) {
  Iterable<TypeReference> iterate() sync* {
    for (final ServerGenericType(:name, :bound) in generics) {
      yield TypeReference((b) {
        b.symbol = name;
        if (bound case final bound?) {
          b.bound = refer(bound.name);
        }
      });
    }
  }

  return iterate().toList();
}
