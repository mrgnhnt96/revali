import 'package:meta/meta.dart';
import 'package:revali_annotations/revali_annotations.dart';

class Middleware {
  const Middleware();

  @nonVirtual
  get<T>() => DI.instance.get<T>();

  void onRequest() {}

  void onResponse() {}
}
