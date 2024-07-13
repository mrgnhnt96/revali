import 'package:revali_router_core/reflect/reflect.dart';
import 'package:revali_router_core/reflect/reflector.dart';

class ReflectHandler {
  ReflectHandler(Set<Reflect> reflects) {
    for (final reflect in reflects) {
      final reflector = Reflector();

      reflect.metas(reflector);

      _reflects[reflect.type] = reflector;
    }
  }

  final Map<Type, Reflector> _reflects = {};

  Reflector? get<T>() {
    return _reflects[T];
  }
}
