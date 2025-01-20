import 'package:revali_router_core/cookies/read_only_cookies.dart';
import 'package:revali_router_core/cookies/same_site_cookie.dart';

abstract class ReadOnlySetCookies implements ReadOnlyCookies {
  const ReadOnlySetCookies();

  String? get sessionId;
  Duration? get maxAge;
  DateTime? get expires;
  String? get domain;
  String? get path;
  bool? get secure;
  bool? get httpOnly;
  SameSiteCookie? get sameSite;
}
