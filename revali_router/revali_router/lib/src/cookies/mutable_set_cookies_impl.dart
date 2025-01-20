import 'dart:io';

import 'package:http_parser/http_parser.dart';
import 'package:revali_router/revali_router.dart';

class MutableSetCookiesImpl extends MutableCookiesImpl
    implements MutableSetCookies {
  MutableSetCookiesImpl([super.values]);

  factory MutableSetCookiesImpl.fromHeader(String? value) {
    final cookies = MutableCookiesImpl.fromHeader(value);

    return MutableSetCookiesImpl(cookies.all);
  }

  @override
  String? get domain => this[SetCookieHeaders.domain];

  @override
  set domain(String? value) {
    switch (value) {
      case null:
        remove(SetCookieHeaders.domain);
      default:
        this[SetCookieHeaders.domain] = value;
    }
  }

  @override
  DateTime? get expires => switch (this[SetCookieHeaders.expires]) {
        null => null,
        final String value => parseHttpDate(value),
      };

  @override
  set expires(DateTime? value) {
    switch (value) {
      case null:
        remove(SetCookieHeaders.expires);
      default:
        this[SetCookieHeaders.expires] = formatHttpDate(value);
    }
  }

  @override
  Duration? get maxAge => switch (this[SetCookieHeaders.maxAge]) {
        null => null,
        final String value => switch (int.tryParse(value)) {
            null => null,
            final int seconds => Duration(seconds: seconds),
          }
      };

  @override
  set maxAge(Duration? value) {
    switch (value) {
      case null:
        remove(SetCookieHeaders.maxAge);
      default:
        this[SetCookieHeaders.maxAge] = value.inSeconds.toString();
    }
  }

  @override
  String? get path => this[SetCookieHeaders.path];

  @override
  set path(String? value) {
    switch (value) {
      case null:
        remove(SetCookieHeaders.path);
      default:
        for (var i = 0; i < value.length; i++) {
          final codeUnit = value.codeUnitAt(i);
          // According to RFC 6265, semicolon and controls
          // should not occur in the path.
          // path-value = <any CHAR except CTLs or ";">
          // CTLs = %x00-1F / %x7F
          if (codeUnit < 0x20 || codeUnit >= 0x7f || codeUnit == 0x3b /*;*/) {
            throw FormatException(
              "Invalid character in cookie path, code unit: '$codeUnit'",
            );
          }
        }

        this[SetCookieHeaders.path] = value;
    }
  }

  @override
  bool? get secure => containsKey(SetCookieHeaders.secure);

  @override
  set secure(bool? value) {
    switch (value) {
      case null:
      case false:
        remove(SetCookieHeaders.secure);
      case true:
        this[SetCookieHeaders.secure] = null;
    }
  }

  @override
  bool? get httpOnly => containsKey(SetCookieHeaders.httpOnly);

  @override
  set httpOnly(bool? httpOnly) {
    switch (httpOnly) {
      case null:
      case false:
        remove(SetCookieHeaders.httpOnly);
      case true:
        this[SetCookieHeaders.httpOnly] = null;
    }
  }

  @override
  SameSiteCookie? get sameSite => switch (this[SetCookieHeaders.sameSite]) {
        null => null,
        final String value => SameSiteCookie.tryParse(value),
      };

  @override
  set sameSite(SameSiteCookie? sameSite) {
    switch (sameSite) {
      case null:
        remove(SetCookieHeaders.sameSite);
      // ignore: no_default_cases
      default:
        this[SetCookieHeaders.sameSite] = sameSite.value;
    }
  }

  @override
  String? get sessionId => this[SetCookieHeaders.sessionId];

  @override
  set sessionId(String? sessionId) {
    switch (sessionId) {
      case null:
        remove(SetCookieHeaders.sessionId);
      default:
        this[SetCookieHeaders.sessionId] = sessionId;
    }
  }

  @override
  String get headerKey => HttpHeaders.setCookieHeader;
}
