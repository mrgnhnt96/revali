import 'package:revali_router_core/reflect/read_only_reflect_handler.dart';
import 'package:revali_router_core/reflect/read_only_reflector.dart';
import 'package:revali_router_core/reflect/reflect.dart';
import 'package:revali_router_core/reflect/reflector.dart';

class ReflectHandler implements ReadOnlyReflectHandler {
  ReflectHandler(Set<Reflect> reflects) {
    for (final reflect in reflects) {
      final reflector = Reflector();

      reflect.metas(reflector);

      _reflects[reflect.type] = reflector;
    }
  }

  final Map<Type, Reflector> _reflects = {};

  @override
  Reflector? get<T>() {
    return _reflects[T];
  }

  @override
  ReadOnlyReflector? byType(Type type) {
    for (final reflect in _reflects.entries) {
      if (reflect.key.runtimeType == type) {
        return reflect.value;
      }
    }

    return null;
  }
}
