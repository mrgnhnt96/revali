import 'package:meta/meta.dart';
import 'package:zora_core/zora_core.dart';

class Middleware {
  const Middleware();

  @nonVirtual
  get<T>() => DI.instance.get<T>();

  void onRequest() {}

  void onResponse() {}
}
