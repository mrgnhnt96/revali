// ignore_for_file: avoid_setters_without_getters

import 'package:revali_router_core/cookies/cookies.dart';
import 'package:revali_router_core/cookies/same_site_cookie.dart';

abstract class SetCookies implements Cookies {
  const SetCookies();

  set sessionId(String? sessionId);
  set maxAge(Duration? maxAge);
  set expires(DateTime? expires);
  set domain(String? domain);
  set path(String? path);
  set secure(bool? secure);
  set httpOnly(bool? httpOnly);
  set sameSite(SameSiteCookie? sameSite);

  String? get sessionId;
  Duration? get maxAge;
  DateTime? get expires;
  String? get domain;
  String? get path;
  bool? get secure;
  bool? get httpOnly;
  SameSiteCookie? get sameSite;
}
