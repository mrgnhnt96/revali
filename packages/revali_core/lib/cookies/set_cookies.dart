// ignore_for_file: avoid_setters_without_getters

import 'package:revali_core/cookies/cookies.dart';
import 'package:revali_core/cookies/same_site_cookie.dart';

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

  /// One formatted `name=value; attr1; attr2=value` string per cookie,
  /// suitable for a distinct `Set-Cookie` header line each — cookies must
  /// never be comma- or semicolon-joined into a single line (RFC 6265
  /// §4.1.1), unlike the request-side `Cookie` header [headerValue].
  List<String> headerValues();
}
