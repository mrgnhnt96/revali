import 'package:meta/meta.dart';
import 'package:zora_annotations/zora_annotations.dart';

class Middleware {
  const Middleware();

  @nonVirtual
  get<T>() => DI.instance.get<T>();

  void onRequest() {}

  void onResponse() {}
}
