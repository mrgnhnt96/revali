// ignore_for_file: avoid_setters_without_getters

import 'package:revali_router_core/cookies/mutable_cookies.dart';
import 'package:revali_router_core/cookies/read_only_set_cookies.dart';
import 'package:revali_router_core/cookies/same_site_cookie.dart';

abstract class MutableSetCookies implements MutableCookies, ReadOnlySetCookies {
  const MutableSetCookies();

  set sessionId(String? sessionId);
  set maxAge(Duration? maxAge);
  set expires(DateTime? expires);
  set domain(String? domain);
  set path(String? path);
  set secure(bool? secure);
  set httpOnly(bool? httpOnly);
  set sameSite(SameSiteCookie? sameSite);
}
