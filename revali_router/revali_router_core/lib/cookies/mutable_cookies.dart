import 'package:revali_router_core/revali_router_core.dart';

abstract class MutableCookies implements ReadOnlyCookies {
  const MutableCookies();

  void operator []=(String key, String? value);
  void remove(String key);
  void clear();

  Map<String, String?> get all;
}
