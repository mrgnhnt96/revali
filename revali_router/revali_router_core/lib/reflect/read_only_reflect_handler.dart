import 'package:revali_router_core/reflect/read_only_reflector.dart';

abstract interface class ReadOnlyReflectHandler {
  const ReadOnlyReflectHandler();

  ReadOnlyReflector? get<T>();

  ReadOnlyReflector? byType(Type type);
}
